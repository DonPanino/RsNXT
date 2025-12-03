package com.opennxt.tools.impl

import com.github.ajalt.clikt.parameters.options.defaultLazy
import com.github.ajalt.clikt.parameters.options.option
import com.github.ajalt.clikt.parameters.types.int
import com.google.common.io.ByteStreams
import com.opennxt.Constants
import com.opennxt.config.RsaConfig
import com.opennxt.config.ServerConfig
import com.opennxt.config.TomlConfig
import com.opennxt.ext.replaceFirst
import com.opennxt.model.files.BinaryType
import com.opennxt.model.files.ClientConfig
import com.opennxt.tools.Tool
import com.opennxt.util.RSAUtil
import com.opennxt.util.Whirlpool
import lzma.sdk.lzma.Encoder
import lzma.streams.LzmaEncoderWrapper
import lzma.streams.LzmaOutputStream
import org.cservenak.streams.Coder
import org.cservenak.streams.CoderOutputStream
import java.io.*
import java.math.BigInteger
import java.nio.file.Files
import java.nio.file.Path
import java.util.*
import java.util.zip.CRC32
import kotlin.system.exitProcess


class ClientPatcher :
    Tool("client-patcher", "Patches all clients and configs files. Uses most recent revision by default") {

    private val RUNESCAPE_REGEX = "^https?://[a-z0-9\\-]*\\.?runescape.com(:[0-9]+)?/\u0000"
    private val RUNESCAPE_CONFIG_URL = "http://www.runescape.com/k=5/l=$(Language:0)/jav_config.ws\u0000"
    private val ASCII = Charsets.US_ASCII

    private val PATCHED_REGEX = "^.*"

    private val version by option(help = "The version of the client to patch")
        .int()
        .defaultLazy {
            val path = Constants.CLIENTS_PATH
            if (!Files.exists(path)) return@defaultLazy -1

            var version = -1
            Files.list(path).forEach {
                try {
                    val thisVersion = it.fileName.toString().toInt()
                    if (version < thisVersion) version = thisVersion
                } catch (e: NumberFormatException) {
                }
            }

            version
        }

    var oldJs5: ByteArray? = null
    var oldLogin: ByteArray? = null
    var oldLauncher: ByteArray? = null

    lateinit var rsaConfig: RsaConfig
    lateinit var serverConfig: ServerConfig

    override fun runTool() {
        logger.info { "Patching clients for version $version" }

        val path = Constants.CLIENTS_PATH.resolve(version.toString())
        if (!Files.exists(path)) throw FileNotFoundException("$path: do clients with version $version exist? did you run `run-tool client-downloader` yet?")

        logger.info { "Patching clients in $path" }
        rsaConfig = try {
            TomlConfig.load(RsaConfig.DEFAULT_PATH, mustExist = true)
        } catch (e: FileNotFoundException) {
            logger.info { "Could not find RSA config: $e. Please run `run-tool rsa-key-generator`" }
            exitProcess(1)
        }
        logger.info { "Using RSA config from ${RsaConfig.DEFAULT_PATH}" }

        serverConfig = TomlConfig.load(ServerConfig.DEFAULT_PATH)
        logger.info { "Using server config from ${ServerConfig.DEFAULT_PATH}" }

        if (serverConfig.configUrl.length >= RUNESCAPE_CONFIG_URL.length) {
            logger.error { "Server config URL length is greater than RuneScape config URL" }
            exitProcess(1)
        }

        BinaryType.values().forEach { type ->
            val fromDirectory =
                Constants.CLIENTS_PATH.resolve(version.toString()).resolve(type.name).resolve("original")
            val toDirectory = Constants.CLIENTS_PATH.resolve(version.toString()).resolve(type.name).resolve("patched")
            if (!Files.exists(toDirectory)) Files.createDirectories(toDirectory)
            val compressedDirectory =
                Constants.CLIENTS_PATH.resolve(version.toString()).resolve(type.name).resolve("compressed")
            if (!Files.exists(compressedDirectory)) Files.createDirectories(compressedDirectory)

            logger.info { "Patching type $type" }
            val config = ClientConfig.load(fromDirectory.resolve("jav_config.ws"))

            config.getFiles().forEach { file ->
                logger.info { "Patching file ${file.name}" }
                val isClient = file.name.contains("rs2client")
                Files.deleteIfExists(toDirectory.resolve(file.name))

                patchFile(type, fromDirectory.resolve(file.name), toDirectory.resolve(file.name), isClient)
            }

            logger.info { "Patching client config" }
            patchConfig(type, config, toDirectory)

            Files.deleteIfExists(compressedDirectory.resolve("jav_config.ws"))
            Files.copy(toDirectory.resolve("jav_config.ws"), compressedDirectory.resolve("jav_config.ws"))
            config.getFiles().forEach { file ->
                val patchedPath = toDirectory.resolve(file.name)
                if (!Files.exists(patchedPath)) {
                    logger.warn { "Patched file missing for ${file.name} at $patchedPath; skipping compression for this type" }
                    return@forEach
                }
                logger.info { "Compressing ${file.name}" }
                val compressed = RSLZMAOutputStream.compress(Files.readAllBytes(patchedPath))
                Files.write(compressedDirectory.resolve(file.name), compressed)
            }
        }

        logger.info { "Patching launchers from ${Constants.LAUNCHERS_PATH}" }
        if (!Files.exists(Constants.LAUNCHERS_PATH) || Files.list(Constants.LAUNCHERS_PATH).count() == 0L) {
            logger.warn { "No launchers found in ${Constants.LAUNCHERS_PATH}" }
            logger.warn { "Unable to patch launchers" }
            logger.warn { "Please place the un-patched Windows launcher in ${Constants.LAUNCHERS_PATH.resolve("win").resolve(
                "original.exe"
            )}" }
            return
        }

        Files.list(Constants.LAUNCHERS_PATH).forEach { type ->
            logger.info { "Patching launcher ${type.fileName}" }

            val from = type.resolve("original.exe")
            val to = type.resolve("patched.exe")

            if (!Files.exists(from))
                throw FileNotFoundException("original (un-patched) launcher at $from")

            logger.info { "Patching launcher $from to $to" }
            patchLauncher(from, to)
        }
    }

    private fun patchConfig(type: BinaryType, config: ClientConfig, filesPath: Path) {
        config["codebase"] = "http://${serverConfig.hostname}/"

        for (i in 0..config.highestParam) {
            val value = config.getParam(i) ?: continue

            if (value.contains("runescape.com") || value.contains("jagex.com")) {
                config["param=$i"] = serverConfig.hostname
            }
        }

        config.getFiles().forEach { file ->
            val filePath = filesPath.resolve(file.name)
            if (!Files.exists(filePath)) {
                logger.warn { "Patched file missing for ${file.name} at $filePath; skipping hash/crc update for this type" }
                return@forEach
            }
            val data = Files.readAllBytes(filePath)
            val id = file.id

            config["download_hash_$id"] = generateFileHash(data, rsaConfig.launcher.modulus, rsaConfig.launcher.exponent)
            config["download_crc_$id"] = crc32(data).toString()
        }

        ClientConfig.save(config, filesPath.resolve("jav_config.ws"))
    }

    private fun patchFile(type: BinaryType, from: Path, to: Path, isClient: Boolean) {
        val raw = Files.readAllBytes(from)

        // nothing to patch in non-client files
        if (!isClient) {
            Files.write(to, raw)
            return
        }

        if (oldJs5 == null) {
            val key = RSAUtil.findRSAKey(raw, 4096)
            if (key == null) {
                logger.warn { "Failed to find js5 RSA key in $from - skipping this binary type" }
                // Do not abort; allow other platform binaries (e.g., WIN64) to provide keys
                return
            }
            oldJs5 = key.toString(16).toByteArray(ASCII)
            logger.info { "Jagex public js5 key: ${key.toString(16)}" }
        }

        if (oldLogin == null) {
            val key = RSAUtil.findRSAKey(raw, 1024)
            if (key == null) {
                logger.warn { "Failed to find login RSA key in $from - skipping this binary type" }
                // Do not abort; allow other platform binaries (e.g., WIN64) to provide keys
                return
            }
            oldLogin = key.toString(16).toByteArray(ASCII)
            logger.info { "Jagex public login key: ${key.toString(16)}" }
        }

        if (!raw.replaceFirst(oldJs5!!, rsaConfig.js5.modulus.toString(16).toByteArray())) {
            logger.warn { "Failed to patch js5 key in ${type.name} - skipping this binary type" }
            return
        }

        if (!raw.replaceFirst(oldLogin!!, rsaConfig.login.modulus.toString(16).toByteArray())) {
            logger.warn { "Failed to patch login key in ${type.name} - skipping this binary type" }
            return
        }

        Files.write(to, raw)
    }

    private fun patchLauncher(from: Path, to: Path) {
        val raw = Files.readAllBytes(from)

        // Try classic ASCII hex replacement for 4096-bit first (older launchers)
        run {
            if (oldLauncher == null) {
                val key = RSAUtil.findRSAKey(raw, 4096)
                if (key != null) {
                    oldLauncher = key.toString(16).toByteArray(ASCII)
                    logger.info { "Found launcher 4096-bit ASCII modulus: ${key.toString(16).take(64)}..." }
                }
            }
            if (oldLauncher != null) {
                if (raw.replaceFirst(oldLauncher!!, rsaConfig.launcher.modulus.toString(16).toByteArray())) {
                    logger.info { "Patched launcher 4096-bit ASCII modulus via text replacement" }
                } else {
                    logger.warn { "Failed to patch launcher 4096-bit ASCII modulus via text replacement" }
                }
            } else {
                logger.info { "No 4096-bit ASCII modulus found in launcher; attempting DER 1024-bit patching" }
            }
        }

        // Fallback: Patch DER-encoded RSA public key moduli (commonly 1024-bit) in the launcher
        val patchedDerCount = patchLauncherDerModuli(raw, rsaConfig.launcher.modulus)
        if (patchedDerCount > 0) {
            logger.info { "Patched $patchedDerCount DER RSA modulus instance(s) in launcher" }
        } else {
            logger.warn { "No DER RSA modulus instances patched in launcher" }
        }

        // Best-effort config URL/regex patch (may not exist in modern launchers)
        if (!raw.replaceFirst(RUNESCAPE_REGEX.toByteArray(ASCII), "${PATCHED_REGEX}\u0000".toByteArray(ASCII))) {
            logger.warn { "Failed to patch launcher regex in $from - continuing" }
        }

        if (!raw.replaceFirst(
                RUNESCAPE_CONFIG_URL.toByteArray(ASCII),
                "${serverConfig.configUrl}\u0000".toByteArray(ASCII)
            )
        ) {
            logger.warn { "Failed to patch launcher config url in $from - continuing" }
        }

        Files.write(to, raw)
    }

    /**
     * Patch DER-encoded RSA public key modulus bytes near the exponent 65537 (02 03 01 00 01).
     * This scans backwards from exponent occurrences to find a preceding INTEGER representing the modulus,
     * and replaces its content with the provided modulus, preserving the original DER length.
     */
    private fun patchLauncherDerModuli(raw: ByteArray, newModulus: BigInteger): Int {
        // DER exponent bytes 0x02 0x03 0x01 0x00 0x01
        val exponentPattern = byteArrayOf(0x02, 0x03, 0x01, 0x00, 0x01)
        val expOffsets = findPatternOffsets(raw, exponentPattern, maxHits = 64)

        if (expOffsets.isEmpty()) return 0

        var patched = 0
        for (expOff in expOffsets) {
            val modInfo = findPrecedingInteger(raw, expOff, windowBack = 8192)
            if (modInfo != null) {
                val (start, length) = modInfo
                // Prepare modulus bytes to fit exactly in 'length' bytes (big-endian)
                var modBytes = newModulus.toByteArray()
                // Drop leading sign byte if present
                if (modBytes.isNotEmpty() && modBytes[0].toInt() == 0) {
                    modBytes = modBytes.copyOfRange(1, modBytes.size)
                }
                modBytes = if (modBytes.size > length) {
                    // If modulus is larger than slot, keep the lower 'length' bytes
                    modBytes.copyOfRange(modBytes.size - length, modBytes.size)
                } else if (modBytes.size < length) {
                    // Left-pad with zeros to match DER length
                    ByteArray(length - modBytes.size) + modBytes
                } else modBytes

                // Replace in-place
                System.arraycopy(modBytes, 0, raw, start, length)
                patched++
            }
        }
        return patched
    }

    /** Find offsets of a byte pattern in data (bounded by maxHits). */
    private fun findPatternOffsets(data: ByteArray, pattern: ByteArray, maxHits: Int): List<Int> {
        val hits = ArrayList<Int>()
        var i = 0
        while (i <= data.size - pattern.size) {
            var ok = true
            var j = 0
            while (j < pattern.size) {
                if (data[i + j] != pattern[j]) { ok = false; break }
                j++
            }
            if (ok) {
                hits.add(i)
                if (hits.size >= maxHits) break
                i += pattern.size
            } else i++
        }
        return hits
    }

    /**
     * Scan backwards from offset to find a DER INTEGER (0x02) and return its content start and length.
     * Supports short, 0x81 and 0x82 length forms. Returns (start, length) of the INTEGER payload.
     */
    private fun findPrecedingInteger(data: ByteArray, fromOffset: Int, windowBack: Int): Pair<Int, Int>? {
        var i = fromOffset - 1
        val min = (fromOffset - windowBack).coerceAtLeast(2)
        while (i > min) {
            if (data[i] == 0x02.toByte()) { // INTEGER tag
                val lenByte = data[i + 1].toInt() and 0xFF
                var len = 0
                var hdr = 0
                when {
                    lenByte == 0x82 -> { len = ((data[i + 2].toInt() and 0xFF) shl 8) or (data[i + 3].toInt() and 0xFF); hdr = 4 }
                    lenByte == 0x81 -> { len = data[i + 2].toInt() and 0xFF; hdr = 3 }
                    lenByte < 0x80 -> { len = lenByte; hdr = 2 }
                    else -> { i--; continue }
                }
                if (len in 128..1024) {
                    val start = i + hdr
                    return Pair(start, len)
                }
            }
            i--
        }
        return null
    }

    private fun crc32(data: ByteArray): Long {
        val crc = CRC32()
        crc.update(data, 0, data.size)
        return crc.value
    }

    companion object {
        fun generateFileHash(data: ByteArray, modulus: BigInteger, exponent: BigInteger): String {
            val hash = ByteArray(65)
            hash[0] = 10
            Whirlpool.getHash(data, 0, data.size).copyInto(hash, 1)

            val rsa = BigInteger(hash).modPow(exponent, modulus).toByteArray()

            return Base64.getEncoder().encodeToString(rsa)
                .replace("\\+".toRegex(), "\\*")
                .replace("/".toRegex(), "\\-")
                .replace("=".toRegex(), "")
        }
    }

    class RSLZMAEncoderWrapper(
        private val encoder: Encoder,
        private val length: Int
    ) : Coder {
        override fun code(`in`: InputStream, out: OutputStream) {
            encoder.writeCoderProperties(out)
            for (i in 0..7) {
                out.write((length.toLong() ushr 8 * i).toInt() and 0xFF)
            }
            encoder.code(`in`, out, -1, -1, null)
        }
    }

    class RSLZMAOutputStream : CoderOutputStream {
        constructor(out: OutputStream, lzmaEncoder: Encoder, length: Int) : super(
            out,
            RSLZMAEncoderWrapper(lzmaEncoder, length)
        )

        constructor(out: OutputStream, wrapper: LzmaEncoderWrapper, length: Int) : super(out, wrapper)

        companion object {
            fun create(out: OutputStream, encoder: Encoder, length: Int): RSLZMAOutputStream {
                encoder.setDictionarySize(1 shl 23)
                encoder.setEndMarkerMode(true)
                encoder.setMatchFinder(1)
                encoder.setNumFastBytes(0x20)
                return RSLZMAOutputStream(out, encoder, length)
            }

            fun compress(data: ByteArray): ByteArray {
                val baos = ByteArrayOutputStream()
                val out = create(baos, Encoder(), data.size)
                out.write(data)
                out.flush()
                out.close()
                return baos.toByteArray()
            }
        }
    }

}
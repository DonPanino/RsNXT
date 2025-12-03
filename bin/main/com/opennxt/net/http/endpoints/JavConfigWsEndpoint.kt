package com.opennxt.net.http.endpoints

import io.netty.channel.ChannelFutureListener
import io.netty.channel.ChannelHandlerContext
import io.netty.handler.codec.http.*
import java.nio.file.Files
import java.nio.file.Paths

object JavConfigWsEndpoint {
    fun handle(ctx: ChannelHandlerContext, msg: FullHttpRequest, query: QueryStringDecoder) {
        // Try to serve a local jav_config.ws from data/config; otherwise return a minimal stub
        val path = Paths.get("data", "config", "jav_config.ws")
        val contentBytes: ByteArray = try {
            if (Files.exists(path)) Files.readAllBytes(path) else minimalConfig()
        } catch (e: Exception) {
            minimalConfig()
        }

        val buf = io.netty.buffer.Unpooled.wrappedBuffer(contentBytes)
        val response = DefaultFullHttpResponse(msg.protocolVersion(), HttpResponseStatus.OK, buf)
        response.headers().set(HttpHeaderNames.SERVER, "JaGeX/3.1")
        response.headers().set(HttpHeaderNames.CONTENT_TYPE, "text/plain")
        response.headers().set(HttpHeaderNames.CONTENT_LENGTH, contentBytes.size)
        ctx.channel().writeAndFlush(response).addListener(ChannelFutureListener.CLOSE)
    }

    private fun minimalConfig(): ByteArray {
        // Minimal jav_config.ws content sufficient for client/patcher flows; adjust as needed
        val text = listOf(
            "param=3",
            "signed=0",
            "codebase=http://127.0.0.1/",
            "initial_jar=rs2client",
            "initial_class=RS2Applet",
            "build=945"
        ).joinToString("\n") + "\n"
        return text.toByteArray(Charsets.UTF_8)
    }
}

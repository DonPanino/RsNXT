package com.opennxt.net.http.endpoints

import io.netty.channel.ChannelFutureListener
import io.netty.channel.ChannelHandlerContext
import io.netty.handler.codec.http.*
import java.nio.file.Files
import java.nio.file.Paths

object ClientFileEndpoint {
    // Serves client files, e.g., /client?name=rs2client.exe
    fun handle(ctx: ChannelHandlerContext, msg: FullHttpRequest, query: QueryStringDecoder) {
        val name = query.parameters()["name"]?.firstOrNull()
        if (name.isNullOrBlank()) {
            val resp = DefaultFullHttpResponse(msg.protocolVersion(), HttpResponseStatus.BAD_REQUEST)
            ctx.channel().writeAndFlush(resp).addListener(ChannelFutureListener.CLOSE)
            return
        }

        val candidate = Paths.get("data", "clients", name)
        if (!Files.exists(candidate)) {
            val resp = DefaultFullHttpResponse(msg.protocolVersion(), HttpResponseStatus.NOT_FOUND)
            ctx.channel().writeAndFlush(resp).addListener(ChannelFutureListener.CLOSE)
            return
        }

        val bytes = Files.readAllBytes(candidate)
        val buf = io.netty.buffer.Unpooled.wrappedBuffer(bytes)
        val response = DefaultFullHttpResponse(msg.protocolVersion(), HttpResponseStatus.OK, buf)
        response.headers().set(HttpHeaderNames.SERVER, "JaGeX/3.1")
        response.headers().set(HttpHeaderNames.CONTENT_TYPE, "application/octet-stream")
        response.headers().set(HttpHeaderNames.CONTENT_LENGTH, bytes.size)
        ctx.channel().writeAndFlush(response).addListener(ChannelFutureListener.CLOSE)
    }
}

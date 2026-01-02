package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	// 配置日志输出到标准错误（方便重定向到文件）
	log.SetOutput(os.Stderr)
	log.SetPrefix("[wasm-test5] ")
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// 1. 定义路由和处理函数
	http.HandleFunc("/go-contact-test5/hello", func(w http.ResponseWriter, r *http.Request) {
		// 修复：向客户端返回内容，同时记录日志
		response := "你好！这是一个 Go 编写的简单服务器。"
		fmt.Fprintf(w, response)
		log.Println(response)
	})

	// 2. 打印启动日志
	log.Println("服务器正在启动，监听端口 :50084...")

	// 3. 启动并监听 50084 端口
	err := http.ListenAndServe(":50084", nil)
	if err != nil {
		// 修复：使用log.Fatal，会打印错误并退出（退出码非0）
		log.Fatalf("服务器启动失败: %s", err)
	}
}

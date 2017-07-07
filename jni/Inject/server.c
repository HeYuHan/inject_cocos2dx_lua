#include "server.h"
#include <stdio.h>   
#include <sys/types.h>   
#include <sys/socket.h>   
#include <netinet/in.h>   
#include <arpa/inet.h> 
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <sys/un.h> 

#define BUFFER_SIZE 40
#define MAX_EVENTS 10
#define BUFF_MAX_SIZE 1024*1024*5
int server_sockfd;// 服务器端套接字   
int client_sockfd;// 客户端套接字 
char revc_buff[BUFF_MAX_SIZE];
char *revc_offset = NULL;
int on_client_msg()
{

}
void reset_buff()
{
	revc_offset = revc_buff;
}
int create_server(const char* server_file)
{
	int ret;
	int clt_size;
  
	static char recv_buf[1024];
	socklen_t clt_addr_len;
	struct sockaddr_un clt_addr;
	struct sockaddr_un srv_addr;

	server_sockfd = socket(PF_UNIX, SOCK_STREAM, 0);
	if (server_sockfd < 0)
	{
		perror("cannot create communication socket");
		return 1;
	}

	// 设置服务器参数  
	srv_addr.sun_family = AF_UNIX;
	strncpy(srv_addr.sun_path, server_file, sizeof(srv_addr.sun_path) - 1);
	unlink(server_file);

	// 绑定socket地址 
	ret = bind(server_sockfd, (struct sockaddr*)&srv_addr, sizeof(srv_addr));
	if (ret == -1)
	{
		perror("cannot bind server socket");
		close(server_sockfd);
		unlink(server_file);
		return 1;
	}

	// 监听   
	ret = listen(server_sockfd, 1);
	if (ret == -1)
	{
		perror("cannot listen the client connect request");
		close(server_sockfd);
		unlink(server_file);
		return 1;
	}

	clt_size = sizeof(struct sockaddr_un);
	// 创建一个epoll句柄
	int epoll_fd;
	epoll_fd = epoll_create(MAX_EVENTS);
	if (epoll_fd == -1)
	{
		perror("epoll_create failed");
		exit(EXIT_FAILURE);
	}
	struct epoll_event ev;// epoll事件结构体
	struct epoll_event events[MAX_EVENTS];// 事件监听队列
	ev.events = EPOLLIN;
	ev.data.fd = server_sockfd;
	// 向epoll注册server_sockfd监听事件
	if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, server_sockfd, &ev) == -1)
	{
		perror("epll_ctl:server_sockfd register failed");
		exit(EXIT_FAILURE);
	}
	int nfds;// epoll监听事件发生的个数
			 // 循环接受客户端请求	
	while (1)
	{
		// 等待事件发生
		nfds = epoll_wait(epoll_fd, events, MAX_EVENTS, -1);
		if (nfds == -1)
		{
			perror("start epoll_wait failed");
			exit(EXIT_FAILURE);
		}
		int i;
		for (i = 0;i < nfds;i++)
		{
			// 客户端有新的连接请求
			if (events[i].data.fd == server_sockfd)
			{
				// 等待客户端连接请求到达
				if ((client_sockfd = accept(server_sockfd, (struct sockaddr_un *)&clt_addr, &clt_size)) < 0)
				{
					perror("accept client_sockfd failed");
					exit(EXIT_FAILURE);
				}
				// 向epoll注册client_sockfd监听事件
				ev.events = EPOLLIN;
				ev.data.fd = client_sockfd;
				if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, client_sockfd, &ev) == -1)
				{
					perror("epoll_ctl:client_sockfd register failed");
					exit(EXIT_FAILURE);
				}
				reset_buff();
				printf("accept client %s/n", clt_addr.sun_path);
			}
			// 客户端有数据发送过来
			else
			{
				int len = recv(client_sockfd, revc_offset, BUFFER_SIZE, 0);
				if (len < 0)
				{
					perror("receive from client failed");
					exit(EXIT_FAILURE);
				}
				revc_offset += len;
				send(client_sockfd, "I have received your message.", 30, 0);
			}
		}
	}
	return 0;
}
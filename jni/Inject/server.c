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
int server_sockfd;// ���������׽���   
int client_sockfd;// �ͻ����׽��� 
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

	// ���÷���������  
	srv_addr.sun_family = AF_UNIX;
	strncpy(srv_addr.sun_path, server_file, sizeof(srv_addr.sun_path) - 1);
	unlink(server_file);

	// ��socket��ַ 
	ret = bind(server_sockfd, (struct sockaddr*)&srv_addr, sizeof(srv_addr));
	if (ret == -1)
	{
		perror("cannot bind server socket");
		close(server_sockfd);
		unlink(server_file);
		return 1;
	}

	// ����   
	ret = listen(server_sockfd, 1);
	if (ret == -1)
	{
		perror("cannot listen the client connect request");
		close(server_sockfd);
		unlink(server_file);
		return 1;
	}

	clt_size = sizeof(struct sockaddr_un);
	// ����һ��epoll���
	int epoll_fd;
	epoll_fd = epoll_create(MAX_EVENTS);
	if (epoll_fd == -1)
	{
		perror("epoll_create failed");
		exit(EXIT_FAILURE);
	}
	struct epoll_event ev;// epoll�¼��ṹ��
	struct epoll_event events[MAX_EVENTS];// �¼���������
	ev.events = EPOLLIN;
	ev.data.fd = server_sockfd;
	// ��epollע��server_sockfd�����¼�
	if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, server_sockfd, &ev) == -1)
	{
		perror("epll_ctl:server_sockfd register failed");
		exit(EXIT_FAILURE);
	}
	int nfds;// epoll�����¼������ĸ���
			 // ѭ�����ܿͻ�������	
	while (1)
	{
		// �ȴ��¼�����
		nfds = epoll_wait(epoll_fd, events, MAX_EVENTS, -1);
		if (nfds == -1)
		{
			perror("start epoll_wait failed");
			exit(EXIT_FAILURE);
		}
		int i;
		for (i = 0;i < nfds;i++)
		{
			// �ͻ������µ���������
			if (events[i].data.fd == server_sockfd)
			{
				// �ȴ��ͻ����������󵽴�
				if ((client_sockfd = accept(server_sockfd, (struct sockaddr_un *)&clt_addr, &clt_size)) < 0)
				{
					perror("accept client_sockfd failed");
					exit(EXIT_FAILURE);
				}
				// ��epollע��client_sockfd�����¼�
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
			// �ͻ��������ݷ��͹���
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
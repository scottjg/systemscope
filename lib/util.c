#include <arpa/inet.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <netdb.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <signal.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>


int connect_with_timeout(int socket, const struct sockaddr *address,
                         socklen_t address_len, int timeout)
{
	fd_set fdset;
	struct timeval tv;
	int r;

	fcntl(socket, F_SETFL, O_NONBLOCK);
	r = connect(socket, address, sizeof(struct sockaddr));
	if (r == 0 || (r == -1 && errno != EINPROGRESS))
		return r;

	FD_ZERO(&fdset);
	FD_SET(socket, &fdset);
	tv.tv_sec = timeout;
	tv.tv_usec = 0;
	if (select(socket + 1, NULL, &fdset, NULL, &tv) == 1)
	{
		int so_error;
		socklen_t len = sizeof so_error;
		getsockopt(socket, SOL_SOCKET, SO_ERROR, &so_error, &len);
		if (so_error == 0) {
			fcntl(socket, F_SETFL, 0);
			return 0;
		}
	}

	errno = ETIMEDOUT;
	return -1;
}

int connect_to_host(const char *host, unsigned short port, int timeout)
{
	struct addrinfo *addr;
	struct addrinfo hints = { 0 };
	int s, status;
	char port_str[16] = { 0 };
	int yes = 1;

	snprintf(port_str, 15, "%u", port);
	hints.ai_family   = AF_INET;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_flags    = AI_PASSIVE;
	if (getaddrinfo(host, port_str, &hints, &addr) != 0) {
		perror("Failed to lookup route");
		goto errout;
	}

	s = socket(addr->ai_family, addr->ai_socktype, addr->ai_protocol);
	if (s < 0) {
		perror("failed to create socket");
		goto errout;
	}

	status = connect_with_timeout(s, addr->ai_addr, addr->ai_addrlen,
	                              timeout);
	if (status != 0) {
		perror("failed to connect");
		goto errclose;
	}

	setsockopt(s, IPPROTO_TCP, TCP_NODELAY, (char *)&yes, sizeof(int));

	return s;

errclose:
	close(s);
errout:
	return -1;
}

ssize_t xread(int fd, void *buf, size_t len)
{
	ssize_t nr;
	while (1) {
		nr = read(fd, buf, len);
		if ((nr < 0) && (errno == EINTR))
			continue;
		return nr;
	}
}

ssize_t xwrite(int fd, const void *buf, size_t len)
{
	ssize_t nr;
	while (1) {
		nr = write(fd, buf, len);
		if ((nr < 0) && (errno == EINTR))
			continue;
		return nr;
	}
}


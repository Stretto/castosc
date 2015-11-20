#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <sys/types.h>
#include <sys/socket.h>

#include <netdb.h>

#include <netinet/in.h>
#include <arpa/inet.h>

#define FATAL(fmt,...) printf("Error: " fmt "\n", ##__VA_ARGS__)


void usage()
{
  printf("oscbridge [options] <server>\n");
}

// Returns: error message
const char* hostToIP(const char* host, struct sockaddr* ip)
{
  struct addrinfo hints;
  struct addrinfo* addrlist;
  struct addrinfo* p;
  const char* errorMsg = NULL;

  memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;

  {
    int result = getaddrinfo(host, NULL, &hints, &addrlist);
    if(result) {
      return "getaddrinfo failed";
    }
  }

  // Find and ipv4 address first
  errorMsg = "no ipv4 or ipv6 address found";
  for(p = addrlist; p != NULL; p = p->ai_next) {
    if(p->ai_addr->sa_family == AF_INET) {
      memcpy(ip, p->ai_addr, sizeof(struct sockaddr_in));
      errorMsg = NULL;
      break;
    }
  }

  
  if(errorMsg) {
    // Check for and ipv6 address
    for(p = addrlist; p != NULL; p = p->ai_next) {
      if(p->ai_addr->sa_family == AF_INET6) {
	memcpy(ip, p->ai_addr, sizeof(struct sockaddr_in6));
	errorMsg = NULL;
	break;
      }
    }
  }

  freeaddrinfo(addrlist);
  return errorMsg;
}

const char* serverName;
struct sockaddr serverIP;

const char* sockinet_ntop(struct sockaddr* addr, char *dst, socklen_t dstLen)
{
  if(addr->sa_family == AF_INET) {
    return inet_ntop(AF_INET, &((struct sockaddr_in*)addr)->sin_addr,
		     dst, dstLen);
  }
  return "UnknownAddressFamily";
}

int main(int argc, const char* argv[])
{
  const char* errorMsg;
  char ipString[64];

  // TODO: get this at runtime somehow
  serverName = "localhost";
  //serverName = argv[1];

  errorMsg = hostToIP(serverName, &serverIP);
  if(errorMsg) {
    FATAL("failed to resolve host '%s': %s (e=%d)", serverName, errorMsg, errno);
    return 1;
  }

  {
    const char* ip = sockinet_ntop(&serverIP, ipString, sizeof(ipString));
    printf("ServerIP: %s\n", ip);
  }


  
  
}

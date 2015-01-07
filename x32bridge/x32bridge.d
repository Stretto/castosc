import std.socket;
import std.getopt : getopt;
import std.stdio : writeln, writefln, stdout;
import std.string : format,startsWith;

import more.common;
import more.net : addressFromIPOrHost;
import more.osc;

enum defaultPort = 10023;
InternetAddress forwardAddress;

void usage()
{
  writeln("x32client [options]");
  writeln("  -f | --forward <addr>  Forward Osc packets to <addr>");
}
void main(string[] args)
{
  string forwardString;

  getopt(args,
	 "f|forward", &forwardString);

  if(forwardString.length) {
    forwardAddress = addressFromIPOrHost(forwardString, defaultPort);
  } else {
    forwardAddress = null;
  }

  ubyte[1024] buffer;

  StdoutWriter stdoutWriter;
  ubyte[16] columnBuffer;
  auto binaryWriter = FormattedBinaryWriter(&stdoutWriter.put, columnBuffer);

  Address addr = new InternetAddress(InternetAddress.ADDR_ANY, defaultPort);

  auto socket = new Socket(addr.addressFamily(), SocketType.DGRAM, ProtocolType.UDP);
  socket.bind(addr);

  //ENABLE BROADCAST!!!!
  socket.setOption(SocketOptionLevel.SOCKET, SocketOption.BROADCAST, 1);

  OscMessage oscMessage;

  Address lastNonForwardAddress = null;
  //auto broadcastAddress = new InternetAddress("255.255.255.255", 10023);
  InternetAddress broadcastAddress = null;

  while(true) {
  //while(false) {
    
    auto length = socket.receiveFrom(buffer, addr);

    void logBuffer()
    {
      binaryWriter.put(buffer[0..length]);
      binaryWriter.finish();
      stdout.flush();
    }

    if(length <= 0) {
      if(length < 0) {
	writefln("socket.receiveFrom failed: %s", socket.getErrorText());
      } else {
	writefln("udp socket closed since receiveFrom returned 0");
      }
      break;
    }

    if(forwardAddress) {
      
      InternetAddress from = cast(InternetAddress)addr;
      if(forwardAddress.addr == from.addr && forwardAddress.port == from.port) {
	writefln("[DEBUG] <<<<<<<<<< received %s bytes from FORWARD(%s)", length, from);
	logBuffer();

	if((cast(char[])buffer).startsWith("/meters") ||
	   (cast(char[])buffer).startsWith("msub_cross_INmtr")) {
	  socket.sendTo(buffer[0..length], broadcastAddress);
	} else {
	  socket.sendTo(buffer[0..length], lastNonForwardAddress);
	}
      } else {
	writefln("[DEBUG] %s != %s", forwardAddress, from);
	writefln("[DEBUG] >>>>>>>>>> received %s bytes from CLIENT(%s)", length, from);
	logBuffer();
	
	//Temp DELETE ME!
	if(!broadcastAddress) {
	  broadcastAddress = new InternetAddress("255.255.255.255", from.port);
	}

	if(lastNonForwardAddress is null)
	  lastNonForwardAddress = new InternetAddress
	    ((cast(InternetAddress)from).addr, ((cast(InternetAddress)from).port));
	socket.sendTo(buffer[0..length], forwardAddress);
      }

    } else {
      writefln("[DEBUG] received %s bytes from %s", length, addr);
      logBuffer();
      try {
	oscMessage.parse(buffer[0..length]);

	if(oscMessage.address == "/info") {
	  //writefln("[DEBUG] todo: handle '/info'");
	  //stdout.flush();
	  auto argBuffer = buffer.ptr + length;
	  length += oscSerializeArgs!true(buffer.ptr + length, "V2.04", "osc-serv", "X32", "2.06");
	  writefln("[DEBUG] sending %s bytes to %s", length, addr);
	  binaryWriter.put(buffer[0..length]);
	  binaryWriter.finish();
	  stdout.flush();
	    
	  socket.sendTo(buffer[0..length], addr);
	    
	} else {
	  writefln("[warning] unknown OSC address '%s'", oscMessage.address);
	  stdout.flush();
	}

      } catch(OscException e) {
	writefln("[error] invalid packet: %s", e.msg);
      }
    }
  }
}

void forward(ubyte[] buffer)
{
  
}

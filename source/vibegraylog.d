module vibegraylog;

import std.array : empty;
import std.stdio;
import vibe.core.log;
import vibe.core.net;
import vibe.core.core : runTask, sleep;
import gelf;

@safe:

struct GrayLoggerConfig {
	string url;
	ushort port;
	string thisHost;
	ulong shortMessageLength;
	ushort chuckSize = 500;
}

class GrayLogger : Logger {
	GrayLoggerConfig config;
	LogLine ll;
	string msg;

	this(GrayLoggerConfig config) {
		this.config = config;
	}

	override void beginLine(ref LogLine ll) @safe {
		this.msg = "";
		this.ll = ll;
	}

	override void put(scope const(char)[] text) @safe {
		this.msg ~= text;
	}

	override void endLine() @trusted {
		import std.algorithm.comparison : min;

		const sMsgLen = min( this.msg.length , this.config.shortMessageLength);
		Message theMessage = Message(this.config.thisHost
				, this.msg.empty
					? "no_message"
					: this.msg[0 .. sMsgLen]
				, vibeLogLevel(this.ll.level)
				);
		theMessage.originalLogLevel = this.ll.level;
		theMessage.file = this.ll.file;
		theMessage.line = this.ll.line;
		theMessage.func = this.ll.func;
		theMessage.threadID = this.ll.threadID;
		theMessage.moduleName = this.ll.mod;
		theMessage.hostTime = this.ll.time.toISOExtString();

		theMessage.full_message = this.msg;
		try {
			auto udp_sender = listenUDP(0);
			udp_sender.connect(this.config.url, this.config.port);
    		foreach(c; Chunks(theMessage, this.config.chuckSize)) {
    		    udp_sender.send(c);
			}
		} catch(Exception e) {
			try {
				writeln(e.toString());
			} catch(Exception f) {
			}
		}
	}
}

@trusted unittest {
	auto cfg = GrayLoggerConfig("127.0.0.1", 12201, "localhost");
	cfg.shortMessageLength = 30;

	auto jl = cast(shared Logger)new GrayLogger(cfg);
	registerLogger(jl);
	logTrace("Trace");
	logDebug("Debug");
	logInfo("Info");
	logError("Error");
	logWarn("Warning");
	logCritical("Critical");
	logFatal("Fatal");
}

pure Level vibeLogLevel(LogLevel ll) {
	final switch(ll) {
		case LogLevel.trace: return Level.DEBUG;
		case LogLevel.debugV: return Level.DEBUG;
		case LogLevel.debug_: return Level.DEBUG;
		case LogLevel.diagnostic: return Level.DEBUG;
		case LogLevel.info: return Level.INFO;
		case LogLevel.warn: return Level.WARNING;
		case LogLevel.error: return Level.ERROR;
		case LogLevel.critical: return Level.CRITICAL;
		case LogLevel.fatal: return Level.EMERGENCY;
		case LogLevel.none: return Level.DEBUG;
	}
}

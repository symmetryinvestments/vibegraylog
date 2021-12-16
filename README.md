# vibejournald

```d
auto cfg = GrayLoggerConfig("127.0.0.1", 12201, "localhost");
auto jl = cast(shared Logger)new GrayLogger(cfg);
registerLogger(jl);

logTrace("Trace");
```

creates a vibe.d logger that logs gelf message to graylog via udp.

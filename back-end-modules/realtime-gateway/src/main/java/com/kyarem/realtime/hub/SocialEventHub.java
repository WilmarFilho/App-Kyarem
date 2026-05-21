package com.kyarem.realtime.hub;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Sinks;

@Component
public class SocialEventHub {

    private static final Logger log = LoggerFactory.getLogger(SocialEventHub.class);

    private final Sinks.Many<String> socialSink = Sinks.many().multicast().onBackpressureBuffer(512);

    public Flux<String> subscribe() {
        log.debug("[realtime-gateway] Cliente conectado ao canal social");
        return socialSink.asFlux();
    }

    public void publish(String payload) {
        Sinks.EmitResult result = socialSink.tryEmitNext(payload);
        if (result.isFailure()) {
            log.warn("[realtime-gateway] Falha ao emitir evento social: {}", result);
        }
    }
}

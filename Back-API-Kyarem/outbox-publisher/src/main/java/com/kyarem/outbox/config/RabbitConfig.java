package com.kyarem.outbox.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Declara o exchange e as filas no RabbitMQ.
 * O outbox-publisher apenas declara — não consome filas.
 */
@Configuration
public class RabbitConfig {
    private static final Logger log = LoggerFactory.getLogger(RabbitConfig.class);

    public static final String EXCHANGE = "kyarem.events";

    // ── Filas consumidas pelos workers downstream ─────────────────────────────

    public static final String QUEUE_PROJECTION_MATCH   = "projection.match";
    public static final String QUEUE_PROJECTION_SOCIAL  = "projection.social";
    public static final String QUEUE_METRICS_RECALC     = "metrics.recalculate";
    public static final String QUEUE_METRICS_RANKING    = "metrics.ranking";
    public static final String QUEUE_REALTIME_NOTIFY    = "realtime.notify";

    @Bean
    public TopicExchange kyaremExchange() {
        return ExchangeBuilder.topicExchange(EXCHANGE).durable(true).build();
    }

    @Bean public Queue projectionMatchQueue()  { return QueueBuilder.durable(QUEUE_PROJECTION_MATCH).build(); }
    @Bean public Queue projectionSocialQueue() { return QueueBuilder.durable(QUEUE_PROJECTION_SOCIAL).build(); }
    @Bean public Queue metricsRecalcQueue()    { return QueueBuilder.durable(QUEUE_METRICS_RECALC).build(); }
    @Bean public Queue metricsRankingQueue()   { return QueueBuilder.durable(QUEUE_METRICS_RANKING).build(); }
    @Bean public Queue realtimeNotifyQueue()   { return QueueBuilder.durable(QUEUE_REALTIME_NOTIFY).build(); }

    // ── Bindings ──────────────────────────────────────────────────────────────

    @Bean public Binding bindProjectionMatchPartida(Queue projectionMatchQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(projectionMatchQueue).to(kyaremExchange).with("partida.#");
    }

    @Bean public Binding bindProjectionMatchEvento(Queue projectionMatchQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(projectionMatchQueue).to(kyaremExchange).with("evento.#");
    }

    @Bean public Binding bindProjectionMatchStatus(Queue projectionMatchQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(projectionMatchQueue).to(kyaremExchange).with("status.#");
    }

    @Bean public Binding bindProjectionMatchSumula(Queue projectionMatchQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(projectionMatchQueue).to(kyaremExchange).with("sumula.#");
    }

    @Bean public Binding bindProjectionSocial(Queue projectionSocialQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(projectionSocialQueue).to(kyaremExchange).with("social.#");
    }

    @Bean public Binding bindMetricsRecalcClosed(Queue metricsRecalcQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(metricsRecalcQueue).to(kyaremExchange).with("sumula.fechada");
    }

    @Bean public Binding bindMetricsRanking(Queue metricsRankingQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(metricsRankingQueue).to(kyaremExchange).with("ranking.requested");
    }

    @Bean public Binding bindRealtimeNotifyPartida(Queue realtimeNotifyQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(realtimeNotifyQueue).to(kyaremExchange).with("partida.#");
    }

    @Bean public Binding bindRealtimeNotifyEvento(Queue realtimeNotifyQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(realtimeNotifyQueue).to(kyaremExchange).with("evento.#");
    }

    @Bean public Binding bindRealtimeNotifyStatus(Queue realtimeNotifyQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(realtimeNotifyQueue).to(kyaremExchange).with("status.#");
    }

    @Bean public Binding bindRealtimeNotifySumula(Queue realtimeNotifyQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(realtimeNotifyQueue).to(kyaremExchange).with("sumula.#");
    }

    // ── RabbitTemplate com JSON converter ────────────────────────────────────

    @Bean
    public Jackson2JsonMessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        template.setMessageConverter(messageConverter());
        template.setMandatory(true);
        template.setReturnsCallback(returned ->
                log.error("[outbox-publisher] Mensagem não roteada: exchange={}, routingKey={}, replyCode={}, replyText={}, body={}",
                        returned.getExchange(),
                        returned.getRoutingKey(),
                        returned.getReplyCode(),
                        returned.getReplyText(),
                        new String(returned.getMessage().getBody())));
        return template;
    }
}

package com.kyarem.metrics.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.ExchangeBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.QueueBuilder;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitTopologyConfig {

    private static final String EXCHANGE = "kyarem.events";
    private static final String QUEUE_METRICS_RECALC = "metrics.recalculate";
    private static final String QUEUE_METRICS_RANKING = "metrics.ranking";

    @Bean
    TopicExchange kyaremExchange() {
        return ExchangeBuilder.topicExchange(EXCHANGE).durable(true).build();
    }

    @Bean
    Queue metricsRecalcQueue() {
        return QueueBuilder.durable(QUEUE_METRICS_RECALC).build();
    }

    @Bean
    Queue metricsRankingQueue() {
        return QueueBuilder.durable(QUEUE_METRICS_RANKING).build();
    }

    @Bean
    Binding bindMetricsRecalcFinished(Queue metricsRecalcQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(metricsRecalcQueue).to(kyaremExchange).with("match.finished");
    }

    @Bean
    Binding bindMetricsRecalcClosed(Queue metricsRecalcQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(metricsRecalcQueue).to(kyaremExchange).with("match.closed");
    }

    @Bean
    Binding bindMetricsRanking(Queue metricsRankingQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(metricsRankingQueue).to(kyaremExchange).with("ranking.requested");
    }
}

package com.kyarem.realtime.config;

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
    private static final String QUEUE_REALTIME_NOTIFY = "realtime.notify";

    @Bean
    TopicExchange kyaremExchange() {
        return ExchangeBuilder.topicExchange(EXCHANGE).durable(true).build();
    }

    @Bean
    Queue realtimeNotifyQueue() {
        return QueueBuilder.durable(QUEUE_REALTIME_NOTIFY).build();
    }

    @Bean
    Binding bindRealtimeNotify(Queue realtimeNotifyQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(realtimeNotifyQueue).to(kyaremExchange).with("match.score.updated");
    }
}

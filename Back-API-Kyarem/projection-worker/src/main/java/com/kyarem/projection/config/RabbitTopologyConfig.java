package com.kyarem.projection.config;

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
    private static final String QUEUE_PROJECTION_MATCH = "projection.match";
    private static final String QUEUE_PROJECTION_SOCIAL = "projection.social";

    @Bean
    TopicExchange kyaremExchange() {
        return ExchangeBuilder.topicExchange(EXCHANGE).durable(true).build();
    }

    @Bean
    Queue projectionMatchQueue() {
        return QueueBuilder.durable(QUEUE_PROJECTION_MATCH).build();
    }

    @Bean
    Queue projectionSocialQueue() {
        return QueueBuilder.durable(QUEUE_PROJECTION_SOCIAL).build();
    }

    @Bean
    Binding bindProjectionMatch(Queue projectionMatchQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(projectionMatchQueue).to(kyaremExchange).with("match.#");
    }

    @Bean
    Binding bindProjectionSocial(Queue projectionSocialQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(projectionSocialQueue).to(kyaremExchange).with("social.#");
    }
}

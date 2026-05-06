package com.kyarem.projection.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.ExchangeBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.QueueBuilder;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Topologia do RabbitMQ para o projection-worker.
 *
 * Routing keys geradas pelo outbox-publisher (conversão PascalCase → snake.case):
 *  PartidaCriada    → partida.criada
 *  PartidaIniciada  → partida.iniciada
 *  StatusAlterado   → status.alterado
 *  SumulaFechada    → sumula.fechada
 *  PartidaExcluida  → partida.excluida
 *  EventoRegistrado → evento.registrado
 *
 * O pattern "partida.#" captura todos os eventos de partida.
 * O pattern "evento.#" captura eventos de jogo (gols, cartões, etc).
 * O pattern "sumula.#" captura o fechamento da súmula.
 * O pattern "status.#" captura mudanças de status.
 */
@Configuration
public class RabbitTopologyConfig {

    private static final String EXCHANGE = "kyarem.events";
    private static final String QUEUE_PROJECTION_MATCH  = "projection.match";
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

    // Captura: partida.criada, partida.iniciada, partida.excluida
    @Bean
    Binding bindProjectionMatchPartida(Queue projectionMatchQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(projectionMatchQueue).to(kyaremExchange).with("partida.#");
    }

    // Captura: evento.registrado (gols, cartões, substituições, etc.)
    @Bean
    Binding bindProjectionMatchEvento(Queue projectionMatchQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(projectionMatchQueue).to(kyaremExchange).with("evento.#");
    }

    // Captura: sumula.fechada
    @Bean
    Binding bindProjectionMatchSumula(Queue projectionMatchQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(projectionMatchQueue).to(kyaremExchange).with("sumula.#");
    }

    // Captura: status.alterado
    @Bean
    Binding bindProjectionMatchStatus(Queue projectionMatchQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(projectionMatchQueue).to(kyaremExchange).with("status.#");
    }

    @Bean
    Binding bindProjectionSocial(Queue projectionSocialQueue, TopicExchange kyaremExchange) {
        return BindingBuilder.bind(projectionSocialQueue).to(kyaremExchange).with("social.#");
    }
}


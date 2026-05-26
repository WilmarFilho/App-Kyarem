package com.nkw.backapisumula.social.repo;

import com.nkw.backapisumula.social.UserFavorite;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserFavoriteRepository extends JpaRepository<UserFavorite, UUID> {

    List<UserFavorite> findByUserIdOrderByCreatedAtDesc(UUID userId);

    Optional<UserFavorite> findByUserIdAndPartida_Id(UUID userId, UUID partidaId);

    Optional<UserFavorite> findByUserIdAndCampeonato_Id(UUID userId, UUID campeonatoId);

    Optional<UserFavorite> findByUserIdAndAtletica_Id(UUID userId, UUID atleticaId);

    boolean existsByUserIdAndPartida_Id(UUID userId, UUID partidaId);

    boolean existsByUserIdAndCampeonato_Id(UUID userId, UUID campeonatoId);

    boolean existsByUserIdAndAtletica_Id(UUID userId, UUID atleticaId);
}

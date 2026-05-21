package com.nkw.backapisumula.social.repo;

import com.nkw.backapisumula.social.SocialPostLike;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface SocialPostLikeRepository extends JpaRepository<SocialPostLike, UUID> {

    boolean existsByPost_IdAndUser_Id(UUID postId, UUID userId);

    Optional<SocialPostLike> findByPost_IdAndUser_Id(UUID postId, UUID userId);
}

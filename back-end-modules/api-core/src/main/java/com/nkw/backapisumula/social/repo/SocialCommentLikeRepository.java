package com.nkw.backapisumula.social.repo;

import com.nkw.backapisumula.social.SocialCommentLike;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface SocialCommentLikeRepository extends JpaRepository<SocialCommentLike, UUID> {

    boolean existsByComment_IdAndUser_Id(UUID commentId, UUID userId);

    Optional<SocialCommentLike> findByComment_IdAndUser_Id(UUID commentId, UUID userId);
}

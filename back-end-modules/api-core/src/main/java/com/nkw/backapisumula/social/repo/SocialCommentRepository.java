package com.nkw.backapisumula.social.repo;

import com.nkw.backapisumula.social.SocialComment;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface SocialCommentRepository extends JpaRepository<SocialComment, UUID> {

    @EntityGraph(attributePaths = {"author", "post", "parentComment"})
    List<SocialComment> findByPost_IdOrderByCreatedAtAsc(UUID postId);

    @EntityGraph(attributePaths = {"author", "post", "parentComment"})
    List<SocialComment> findByPost_IdAndParentCommentIsNullOrderByCreatedAtAsc(UUID postId);
}

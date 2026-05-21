package com.nkw.backapisumula.social.repo;

import com.nkw.backapisumula.social.SocialPost;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface SocialPostRepository extends JpaRepository<SocialPost, UUID> {

    @EntityGraph(attributePaths = "author")
    @Query("""
            select p
            from SocialPost p
            where p.author.id = :viewerId
               or p.author.id in (
                    select f.followed.id
                    from SocialFollow f
                    where f.follower.id = :viewerId
               )
            order by p.createdAt desc
            """)
    List<SocialPost> findFeedPosts(@Param("viewerId") UUID viewerId, Pageable pageable);

    @EntityGraph(attributePaths = "author")
    @Query("""
            select p
            from SocialPost p
            where p.author.id = :authorId
            order by p.createdAt desc
            """)
    List<SocialPost> findProfilePosts(@Param("authorId") UUID authorId, Pageable pageable);

    long countByAuthor_Id(UUID authorId);
}

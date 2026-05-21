package com.nkw.backapisumula.social.repo;

import com.nkw.backapisumula.social.SocialFollow;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface SocialFollowRepository extends JpaRepository<SocialFollow, UUID> {

    boolean existsByFollower_IdAndFollowed_Id(UUID followerUserId, UUID followedUserId);

    Optional<SocialFollow> findByFollower_IdAndFollowed_Id(UUID followerUserId, UUID followedUserId);

    long countByFollower_Id(UUID followerUserId);

    long countByFollowed_Id(UUID followedUserId);
}

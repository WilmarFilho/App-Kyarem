package com.nkw.backapisumula.identity.repo;

import com.nkw.backapisumula.identity.Profile;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface ProfileRepository extends JpaRepository<Profile, UUID> {}

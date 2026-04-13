package com.nkw.backapisumula.common.log;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.UUID;

public interface ApplicationLogRepository extends JpaRepository<ApplicationLog, UUID>, JpaSpecificationExecutor<ApplicationLog> {
}

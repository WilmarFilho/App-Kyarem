package com.nkw.backapisumula.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(name = "usuarios_roles_globais", schema = "operational")
@IdClass(UsuarioRoleGlobal.UsuarioRoleGlobalId.class)
public class UsuarioRoleGlobal {

    @Id
    @Column(name = "user_id", columnDefinition = "uuid")
    private UUID userId;

    @Id
    @Column(nullable = false)
    private String role;

    @Column(name = "criado_em")
    private OffsetDateTime criadoEm;

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public OffsetDateTime getCriadoEm() {
        return criadoEm;
    }

    public void setCriadoEm(OffsetDateTime criadoEm) {
        this.criadoEm = criadoEm;
    }

    public static class UsuarioRoleGlobalId implements Serializable {
        private UUID userId;
        private String role;

        public UsuarioRoleGlobalId() {
        }

        public UsuarioRoleGlobalId(UUID userId, String role) {
            this.userId = userId;
            this.role = role;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) {
                return true;
            }
            if (!(o instanceof UsuarioRoleGlobalId that)) {
                return false;
            }
            return Objects.equals(userId, that.userId) && Objects.equals(role, that.role);
        }

        @Override
        public int hashCode() {
            return Objects.hash(userId, role);
        }
    }
}

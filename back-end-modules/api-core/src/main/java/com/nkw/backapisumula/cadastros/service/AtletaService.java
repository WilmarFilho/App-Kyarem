package com.nkw.backapisumula.cadastros.service;

import com.nkw.backapisumula.cadastros.Atleta;
import com.nkw.backapisumula.cadastros.repo.AtletaRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class AtletaService {

    private final AtletaRepository repo;

    @PersistenceContext
    private EntityManager entityManager;

    public AtletaService(AtletaRepository repo) {
        this.repo = repo;
    }

    @SuppressWarnings("unchecked")
    public List<Atleta> listAll(UUID atleticaId) {
        String sql = """
                SELECT DISTINCT p.*
                FROM operational.profiles p
                JOIN operational.atletica_membros am ON am.user_id = p.id
                WHERE am.papel_codigo = 'ATHLETE'
                  AND am.status = 'ATIVO'
                """;
        if (atleticaId != null) {
            sql += " AND am.atletica_id = :atleticaId";
        }
        sql += " ORDER BY COALESCE(NULLIF(p.nome_exibicao, ''), p.nome_completo)";

        var query = entityManager.createNativeQuery(sql, Atleta.class);
        if (atleticaId != null) {
            query.setParameter("atleticaId", atleticaId);
        }
        return query.getResultList();
    }

    public Atleta getOrThrow(UUID id) {
        return repo.findById(id).orElseThrow(() -> new IllegalArgumentException("Atleta não encontrado."));
    }

    public Atleta create(String nome, String fotoUrl) {
        throw new IllegalStateException("Cadastro direto de atleta foi removido. Use profiles + atletica_membros.");
    }

    public Atleta update(UUID id, String nome) {
        throw new IllegalStateException("Atualização direta de atleta foi removida. Atualize o profile do usuário.");
    }

    public void delete(UUID id) {
        throw new IllegalStateException("Exclusão direta de atleta foi removida. Gerencie o vínculo em atletica_membros.");
    }
}

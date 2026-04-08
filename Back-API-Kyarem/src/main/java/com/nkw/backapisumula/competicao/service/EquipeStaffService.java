package com.nkw.backapisumula.competicao.service;

import com.nkw.backapisumula.competicao.Equipe;
import com.nkw.backapisumula.competicao.EquipeStaff;
import com.nkw.backapisumula.competicao.repo.EquipeRepository;
import com.nkw.backapisumula.competicao.repo.EquipeStaffRepository;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Service
public class EquipeStaffService {

    private final EquipeStaffRepository repo;
    private final EquipeRepository equipeRepo;

    public EquipeStaffService(EquipeStaffRepository repo, EquipeRepository equipeRepo) {
        this.repo = repo;
        this.equipeRepo = equipeRepo;
    }

    public List<EquipeStaff> listByEquipe(UUID equipeId) {
        getEquipeOrThrow(equipeId);
        return repo.findByEquipe_Id(equipeId).stream()
                .sorted(Comparator.comparing(
                        EquipeStaff::getCriadoEm,
                        Comparator.nullsLast(Comparator.reverseOrder())
                ))
                .toList();
    }

    public EquipeStaff add(UUID equipeId, String nome, String cargo) {
        Equipe equipe = getEquipeOrThrow(equipeId);

        EquipeStaff staff = new EquipeStaff();
        staff.setEquipe(equipe);
        staff.setNome(nome.trim());
        staff.setCargo(cargo.trim());
        staff.setCriadoEm(OffsetDateTime.now());
        return repo.save(staff);
    }

    public void remove(UUID equipeId, UUID staffId) {
        getEquipeOrThrow(equipeId);
        EquipeStaff staff = repo.findById(staffId)
                .orElseThrow(() -> new IllegalArgumentException("Membro do staff não encontrado."));

        if (staff.getEquipe() == null || !equipeId.equals(staff.getEquipe().getId())) {
            throw new IllegalArgumentException("Membro do staff não pertence à equipe informada.");
        }

        repo.delete(staff);
    }

    private Equipe getEquipeOrThrow(UUID equipeId) {
        return equipeRepo.findById(equipeId)
                .orElseThrow(() -> new IllegalArgumentException("Equipe não encontrada."));
    }
}

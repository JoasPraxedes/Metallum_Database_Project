-- Criação de Procedure  para admitir membro
CREATE OR REPLACE PROCEDURE SP_AdmitirMembro(PIdProjeto in number, PNomeMusico in varchar2, PAnoEntrada in number, PStatus in varchar2)
AS
v_IdMusico number(5);
v_Contador number(5);
v_ProxId number(5);
BEGIN
 --Buscando ID do músico pelo nome
    SELECT IdMusico INTO v_IdMusico FROM TB_MUSICO WHERE nomeartistico = PNomeMusico;
    
 -- Verificando se ele já está ativo no projeto
    SELECT COUNT(*) INTO v_Contador
    FROM TB_MEMBROS
    WHERE IdProjeto = PIdProjeto
     AND IdMusico = v_IdMusico
     AND AnoSaida is NULL;
     
 -- Validação
    IF v_Contador > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Conflito: Músico já registrado como ativo');
    ELSE
        SELECT MAX(IdMembro) + 1 INTO v_ProxId FROM TB_MEMBROS;
        
        INSERT INTO TB_MEMBROS (IdMembro, IdProjeto, IdMusico, AnoEntrada, StatusNoProjeto)
        VALUES (v_ProxId, PIdProjeto, v_IdMusico, PAnoEntrada, PStatus);
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Sucesso: ' || PNomeMusico || ' agora faz parte do projeto!');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Erro: Músico não encontradado na base de dados.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Erro inesperado: ' || SQLERRM);
END;

-- Ativa a visualização de mensagens no console
SET SERVEROUTPUT ON;

-- Tenta admitir o Max Cavalera no Sepultura (Supondo que o ID do Sepultura seja 1001)
EXEC SP_ADMITIRMEMBRO(1001, 'Max Cavalera', 2026, 'Convidado Especial');


-- Criação de Procedure para exclussão de músico
CREATE OR REPLACE PROCEDURE SP_EXCLUI_MUSICO(PIdMusico number)
AS
v_nome varchar2(50);
Begin
	-- Buscando o músico na tabela TB_MUSICO
	SELECT NomeArtistico INTO v_nome FROM TB_MUSICO WHERE IdMusico = PIdMusico;

	-- Excluindo da o músico das tabelas Membros,musico toca instrumento e musico tem carreira solo
	DELETE FROM TB_MEMBROS WHERE IdMusico = PIdMusico;
	DELETE FROM TB_MUSICO_TEM_CARREIRASOLO WHERE IdMusico = PIdMusico;
	DELETE FROM TB_MUSICO_TOCA_INSTRUMENTO WHERE IdMusico = PIdMusico;

	-- Excluindo músico da tabela TB_MUSICO
	DELETE FROM TB_MUSICO WHERE IdMusico = PIdMusico;

	COMMIT;
	DBMS_OUTPUT.PUT_LINE('Sucesso: O músico ' || v_nome || ' (ID: ' || PIdMusico || ') e todas as suas relações foram removidos.');	
	
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RAISE_APPLICATION_ERROR(-20004,'Erro: Músico com ID:' || PIdMusico || 'não encontrado na base de dados');
	WHEN OTHERS THEN
        ROLLBACK;
		RAISE_APPLICATION_ERROR(-20005,'Erro inesperado' || SQLERRM);
END;
 -- Executando Procedure
 SELECT * FROM TB_MUSICO;
 
 EXEC sp_exclui_musico(100);
 
-- Criando Procedure para mudar a gravadora da banda.
CREATE OR REPLACE PROCEDURE SP_MIGRAR_BANDA_GRAVADORA(PNomeBanda varchar2, PNomeNovaLabel varchar2)
AS
v_IdLabel TB_LABEL.IdLabel%TYPE;
v_IdProjeto TB_PROJETO_MUSICAL.IdProjeto%TYPE;
BEGIN
	-- Buscando o Id do Projeto
    BEGIN
        SELECT IdProjeto INTO v_IdProjeto FROM TB_PROJETO_MUSICAL 
        WHERE Nome = PNomeBanda;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20006,'Erro: Banda ' || PNomeBanda || ' não encontrada na base de dados');
    END;
 	
	-- Buscando o Id do Projeto
    BEGIN
        SELECT IdLabel INTO v_IdLabel FROM TB_LABEL
        WHERE NomeFantasia = PNomeNovaLabel;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20007,'Erro: Label ' || PNomeNovaLabel ||' não encontrada na base de dados');
    END;
    
	-- Atualizando o Label
	UPDATE TB_PROJETO_MUSICAL SET IdLabel = v_IdLabel
	WHERE IdProjeto = v_IdProjeto;

	COMMIT;
	DBMS_OUTPUT.PUT_LINE('Banda '|| PNomeBanda || ' movida para a gravadora '|| PNomeNovaLabel || ' em ' || sysdate);

EXCEPTION
	WHEN OTHERS THEN
        ROLLBACK;
		RAISE_APPLICATION_ERROR(-20009,'Erro inesperado' || SQLERRM);
END;
-- Executando a procedure
SELECT * FROM TB_PROJETO_MUSICAL;

SELECT * FROM TB_LABEL;
-- Cenário de sucesso
EXEC SP_MIGRAR_BANDA_GRAVADORA('Sepultura', 'Nuclear Blast');

-- Cenário de erro (Gravadora inexistente)
EXEC SP_MIGRAR_BANDA_GRAVADORA('Sepultura', 'Gravadora Fantasma');


-- Criando Procedure para encerrar um projeto
CREATE OR REPLACE PROCEDURE SP_ENCERRAR_PROJETO(PNomeProjeto varchar2, PAnoEncerramento number)
AS
v_IdProjeto TB_PROJETO_MUSICAL.IdProjeto%TYPE;
BEGIN
    -- Buscando o ID do Projeto
	BEGIN
		SELECT IdProjeto into v_IdProjeto FROM TB_PROJETO_MUSICAL
		WHERE Nome = PNomeProjeto;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20010, 'Erro: Projeto ' || PNomeProjeto || ' não encontrado na base de dados.');
	END;

	--Atualizando o status do Projeto
	UPDATE TB_PROJETO_MUSICAL SET Status = 'Split- Up', AnosAtividade =  SUBSTR(AnosAtividade,1,5) || PAnoEncerramento
    WHERE IdProjeto = v_IdProjeto;

	--Atualizando o Ano de Saída na TB_MEMBROS
	UPDATE TB_MEMBROS SET AnoSaida = PAnoEncerramento WHERE IdProjeto = v_IdProjeto AND AnoSaida IS NULL;

	COMMIT;
	DBMS_OUTPUT.PUT_LINE('Projeto '|| PNomeProjeto || ' encerrado no ano '|| PAnoEncerramento);

EXCEPTION
	WHEN OTHERS THEN
        ROLLBACK;
		RAISE_APPLICATION_ERROR(-20012,'Erro inesperado' || SQLERRM);
END;
-- Executando 
SELECT * FROM TB_PROJETO_MUSICAL;

EXEC SP_ENCERRAR_PROJETO('Sepultura', 2026);

-- Criando Procedure para adcionar músicos
CREATE OR REPLACE PROCEDURE SP_ADICIONAR_MUSICO(PNomeReal varchar2, PNomeArtistico varchar2, DataNascimento date, PGenero varchar2, PNacionalidade varchar2, PDescricao varchar2)
AS
v_Cont number(5);
v_ProxId TB_MUSICO.IdMusico%TYPE;
BEGIN
 -- Verificando se o musico já existe
	SELECT COUNT(*) INTO v_Cont
	FROM TB_MUSICO
	WHERE NomeReal = PNomeReal;

 -- Validando
	IF v_Cont > 0 THEN
		RAISE_APPLICATION_ERROR(-20025, 'Erro: Músico ' || PNomeReal ||' já registrado');
    	ELSE
		-- NVL garante que se a tabela estiver vazia, o ID comece em 1
        	SELECT MAX(IdMusico) + 1 INTO v_ProxId FROM TB_MUSICO;
        
       		INSERT INTO TB_MUSICO (IdMusico, NomeReal, NomeArtistico, DataNascimento, Genero, Nacionalidade, DescricaoCuriosidades)
        	VALUES (v_ProxId, PNomeReal, PNomeArtistico, DataNascimento, PGenero, PNacionalidade, PDescricao);
        
        	COMMIT;
        	DBMS_OUTPUT.PUT_LINE('Sucesso: ' || PNomeReal || ' agora faz parte da base de dados!');
    		END IF;
EXCEPTION
    WHEN OTHERS THEN
	ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'Erro inesperado: ' || SQLERRM);
END;

-- Executando
EXEC SP_ADICIONAR_MUSICO('Paul Bruce Dickinson', 'Bruce Dickinson', TO_DATE('07/08/1958', 'DD/MM/YYYY'), 'M', 'Britânico', 'Vocalista do Iron Maiden e piloto.');

SELECT * FROM TB_MUSICO;
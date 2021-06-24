GO
-- Triggers

-- verificar se email ja existe
-- DROP TRIGGER Proj.[trigger_pessoa]
-- GO

CREATE TRIGGER Proj.[trigger_register_pessoa] ON Proj.[pessoa] --registar pessoa nova
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @nif INT, @nome VARCHAR(50), @birth DATE, @endereco VARCHAR(50), @email VARCHAR(50), @num_tlm INT, @password VARCHAR(50);
    
    SELECT @nif=nif, @nome=nome, @birth=birth, @endereco=endereco, @email=email, @num_tlm=num_tlm, @password=CONVERT(VARCHAR(20), DECRYPTBYPASSPHRASE('**********',[password])) FROM inserted;
		IF ((SELECT p5g5.Proj.[udf_validateEmail](@email)) > 0)  -- existe na base de dados pessoa c esse email
			RAISERROR('Email is already registered!', 16, 1)
		ELSE
			INSERT INTO p5g5.Proj.[pessoa](nif, nome, birth, endereco, email, num_tlm, [password])
			VALUES (@nif, @nome, @birth, @endereco, @email, @num_tlm, ENCRYPTBYPASSPHRASE('**********', @password))
END
GO

-- ver se já existe marcacao no dia escolhido pelo interessado
-- DROP TRIGGER Proj.[trigger_marcacao]
-- GO

CREATE TRIGGER Proj.[trigger_marcacao] ON Proj.[marcacao]
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @data_marc DATE, @interessado_nif INT, @imovel_codigo VARCHAR(5), @now DATE, @responseMessage NVARCHAR(250)
	SET @now = CAST(DATEADD(DAY, 1, GETDATE()) AS DATE)
	SET @responseMessage='Success'

	SELECT @data_marc=data_marc, @interessado_nif=interessado_nif, @imovel_codigo=imovel_codigo FROM INSERTED;
	-- checkar se data é valida
	IF NOT EXISTS(SELECT data_marc FROM p5g5.Proj.[marcacao] JOIN p5g5.Proj.[imovel] AS I ON I.imovel_codigo= @imovel_codigo WHERE data_marc=@data_marc)
	BEGIN
		-- verificar se a data é maior q agora
		IF @data_marc > @now
		BEGIN
			-- criar interessado se ele ainda n ta na tablea
		IF NOT EXISTS(SELECT interessado_nif FROM p5g5.Proj.[interessado] WHERE interessado_nif = @interessado_nif)
			EXEC Proj.[cp_create_interessado] @interessado_nif, @responseMessage OUTPUT

			IF @responseMessage = 'Success'
				INSERT INTO Proj.[marcacao](data_marc, interessado_nif, imovel_codigo)
							VALUES (@data_marc, @interessado_nif, @imovel_codigo)
				SET @responseMessage='Success'
		END
		ELSE
			RAISERROR('Please select a future date', 16, 1)
	END
	ELSE
		RAISERROR('Impossible date', 16, 1)
END
GO

CREATE TRIGGER  Proj.[trigger_comercial] ON Proj.[comercial]
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @imovel_codigo VARCHAR(5), @estacionamento BIT, @tipo_comercial_id INT
	SELECT @imovel_codigo=imovel_codigo, @estacionamento=estacionamento, @tipo_comercial_id=tipo_comercial_id FROM INSERTED
	
	IF EXISTS(SELECT imovel_codigo FROM p5g5.Proj.[imovel] WHERE imovel_codigo=@imovel_codigo)	-- se imovel existe
		INSERT INTO Proj.[comercial](imovel_codigo, estacionamento, tipo_comercial_id)
			VALUES(@imovel_codigo, @estacionamento, @tipo_comercial_id)
	ELSE
		RAISERROR('Couldnt add comercial..', 16, 1)
END
GO

--CREATE TRIGGER  Proj.[trigger_habitacional] ON Proj.[habitacional]
--INSTEAD OF INSERT
--AS
--BEGIN
--	DECLARE @imovel_codigo VARCHAR(5), @num_quartos INT, @wcs INT, @tipo_habitacional_id INT
--	SELECT @imovel_codigo=imovel_codigo, @num_quartos=num_quartos, @wcs=wcs, @tipo_habitacional_id=tipo_habitacional_id FROM INSERTED
	
--	IF EXISTS(SELECT imovel_codigo FROM p5g5.Proj.[imovel] WHERE imovel_codigo=@imovel_codigo)	-- se imovel existe
--		INSERT INTO Proj.[habitacional](imovel_codigo, num_quartos, wcs, tipo_habitacional_id) -- aqui fazem se vericacoes de id? tp se for terreno wc e quarto = 0
--			VALUES(@imovel_codigo, @num_quartos, @wcs, @tipo_habitacional_id)
--	ELSE
--		RAISERROR('Couldnt add habitacional..', 16, 1)
--END
--GO


CREATE TRIGGER  Proj.[trigger_addon] ON Proj.[temAddOn]
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @quantidade INT, @habitacional_codigo VARCHAR(5), @add_on_id INT
	SELECT @quantidade=quantidade, @habitacional_codigo=habitacional_codigo, @add_on_id=add_on_id FROM INSERTED
	
	IF EXISTS(SELECT I.imovel_codigo FROM p5g5.Proj.[imovel] AS I JOIN p5g5.Proj.[habitacional] AS H ON I.imovel_codigo=H.imovel_codigo 
					WHERE I.imovel_codigo=@habitacional_codigo)	-- se imovel existe

		INSERT INTO Proj.[temAddOn](quantidade, habitacional_codigo, add_on_id)
			VALUES(@quantidade, @habitacional_codigo, @add_on_id)
	ELSE
		RAISERROR('Couldnt add add on..', 16, 1)
END
GO


-- FAZER MAIS TRIGGERS FDSAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 

-- FAZER INDEXES
-- FAZER TRANSACOES
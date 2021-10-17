class SearchController < ApplicationController

  skip_before_action :verify_authenticity_token

  URL_IMAGE = "https://static2.meucarronovo.com.br/imagens-dinamicas/detalhe/fotos/"
  URL = "https://www.meucarronovo.com.br/api/v2/busca?"

  def index
    @filtro = {cidade: 'Francisco Beltrão'}
  end

  def filtrar
    @filtro = {cidade: params["cidade"]}
    puts "params #{params}"
    url = nil
    @json = []
    @alerta = nil
    @sucesso= nil
    @mechanize = Mechanize.new
    if params["marca"].empty? && params["modelo"].empty? && params["tipo"].empty? && params["cidade"].empty?
      @alerta = "Nenhum campo preenchido!"  
      return retorno() 
    end
    
    url = URL + "tipoVeiculo="+ params["tipo"] if !params["tipo"].empty? && params["tipo"] != "0"
    if !params["tipo"].empty? && !params["cidade"].empty? && !params["tipo"].empty? && params["tipo"] != "0"
      url = url + "&cidade="+ params["cidade"] 
    else
      url = URL + "cidade="+ params["cidade"] 
    end
    puts "URL #{url}"

    pagina = @mechanize.get(url)
    resultado = JSON.parse(pagina.body)
    
    if(resultado["total"] < 1)
      @alerta = "Nenhum resultado encontrado!"
      return retorno()
    end  
    procurarVeiculos(resultado)
  end

  def procurarVeiculos(resultado)
    documentos = resultado["documentos"].find_all { |doc| doc["marcaNome"].downcase.include?(params["marca"].downcase) && doc["modeloNome"].downcase.include?(params["modelo"].downcase)}
    documentos.each do |doc|
      veiculo = {}
      nome_veiculo = nil
      if (doc["modeloNome"].lstrip.match(/(^\w+)/).size > 1)
        nome_veiculo = doc["modeloNome"].lstrip.match(/(^\w+)/)[1].capitalize
      end
      nome_imagem = "#{doc["marcaNome"].capitalize}"
      nome_imagem += "_"+nome_veiculo if !nome_veiculo.nil? 
      nome_imagem += "_"+ doc["preco"].to_s

      caminho_imagem = "public/imagens/#{nome_imagem}"
      veiculo[:modelo] = doc["modeloNome"]
      veiculo[:marca] = doc["marcaNome"]
      veiculo[:valor] = doc["preco"]
      veiculo[:ano_fabricacao] = doc["anoFabricacao"]
      veiculo[:ano_modelo] = doc["anoModelo"]
      veiculo[:local_path] = caminho_imagem
      salvarImagem(veiculo, doc["fotoCapa"])
      @json.push(veiculo)
      @sucesso = "Achamos o seu veiculo! :)"
    end
    puts "JSON >>>>>>>>>>: #{@json}"
    retorno()
  end

  def retorno
    respond_to do |format|
      format.html { render action: "index" }
      format.json { render json: @json, status: !@sucesso.nil? ||  !@alerta.nil?}
    end
  end

  def salvarImagem(veiculo, foto_capa)
    File.delete(veiculo[:local_path]) if File.exist?(veiculo[:local_path])
    imagem = @mechanize.get(URL_IMAGE+foto_capa).save(veiculo[:local_path])
  end

end

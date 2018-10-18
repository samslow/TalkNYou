class KakaoController < ApplicationController
  def keyboard
    
    @keyboard = {
      type: "buttons",
      :buttons => ["사이트 리스트","환경설정", "오늘고양이"]
    }
    
    render json: @keyboard
  end

  def message
    @user_msg = params[:content] #사용자의 입력값
    p "검토합니다"
    p params[:user_key]
    p "검토 끝"
    User.create(key: params[:user_key])
    if @user_msg == "환경설정"
      @text = "환경설정 세션이라능"
    elsif @user_msg == "오늘고양이"
      @url = "http://thecatapi.com/api/images/get?format=xml&type=jpg"
      @cat_xml = RestClient.get(@url)
      @cat_doc = Nokogiri::XML(@cat_xml) #:: 는 모듈안에 있다는 뜻 'nokogiri' 안의 xml 모듈 
      @cat_url = @cat_doc.xpath("//url").text
    elsif @user_msg == "버튼 선택"
      @text = "버튼을 선택하라능"
    elsif @user_msg == "계정 관리"
      @text = "비밀번호나 리듬을 관리하는 세션이라능"
    elsif @user_msg == "홈으로"
      @text = "홈으로 돌아왔다능.."
    elsif @user_msg == "PW/리듬 설정"
      @text = "보안 그 너머로.."
    else
      @text = "잘못된 입력이라능!"
      
    end
    
    @return_msg = {
      :text => @text #옵셔널은 지움 (ex, photo, message_button)
    }
    @return_keyboard = {
       type: "buttons",
      :buttons => ["사이트 리스트","환경설정", "오늘고양이"]
      }
    @config_keyboard = {
       type: "buttons",
      :buttons => ["PW/리듬 설정","계정 관리", "홈으로"]
      }
    @account_keyboard = {
      type: "buttons",
      buttons: ["비밀번호 관리", "리듬 관리", "홈으로"]
    }
      
      
    
    if @user_msg == "오늘고양이"
        @result = {
        :message => {
          :text => "고양이가 당신을 축복합니다! 냥냥",
          :photo => {
          :url => @cat_url,
          :width => 720, 
          :height => 630
        }
      },
        :keyboard => @return_keyboard
      }
    elsif @user_msg == "환경설정"
      @result = {
        :message => @return_msg,
        :keyboard => @config_keyboard
      }
    elsif @user_msg == "계정 관리"
      @result = {
        message: @return_msg,
        keyboard: @account_keyboard
      }
    elsif @user_msg == "PW/리듬 설정"
      @result = {
        message: @return_msg,
        keyboard: {
          type: "buttons",
          buttons: ["비밀번호 관리","리듬 관리","홈으로"]
        }
      }
    else
        @result = {
        :message => @return_msg,
        :keyboard => @return_keyboard
      }
    end
    
    render json: @result
  end
end

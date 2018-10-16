class KakaoController < ApplicationController
  def keyboard
    @keyboard = {
      type: "buttons",
      :buttons => ["버튼 선택","오늘고양이"]
    }
    render json: @keyboard
  end

  def message
    @user_msg = params[:content] #사용자의 입력값
    
    if @user_msg == "기념일"
      @text = "8월 28일"
    elsif @user_msg == "로또"
      @text = "냥냥이가 뽑은 이번주의 로또번호는..? \n" + (1..45).to_a.sample(6).sort.to_s + "이다 냥!!"
    elsif @user_msg == "메뉴선택"
      @text = ["한식", "일식", "중식", "양식"].sample.to_s
    elsif @user_msg == "오늘까지몇일?"
      @text = ((-(Date.new(2017,8,28) - Date.today)).to_i + 1).to_s + "일째 연애중♥"
    elsif @user_msg == "앞으로의 약속"
      @text = "7월 7일 보드게임콘테스트"
    elsif @user_msg == "오늘고양이"
      @url = "http://thecatapi.com/api/images/get?format=xml&type=jpg"
      @cat_xml = RestClient.get(@url)
      @cat_doc = Nokogiri::XML(@cat_xml) #:: 는 모듈안에 있다는 뜻 'nokogiri' 안의 xml 모듈 
      @cat_url = @cat_doc.xpath("//url").text
      # @text = @cat_url.text
      
    end
    
    @return_msg = {
      :text => @text #옵셔널은 지움 (ex, photo, message_button)
    }
    @return_msg_addphoto = {
      :text => "고양이가 당신을 축복합니다! 냥냥",
      :photo => {
        :url => @cat_url,
        :width => 720, 
        :height => 630
      }
    }
    @return_keyboard = {
       type: "buttons",
       :buttons => ["버튼 선택","오늘고양이"]
      }
    
    if @user_msg == "오늘고양이"
        @result = {
        :message => @return_msg_addphoto,
        :keyboard => @return_keyboard
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

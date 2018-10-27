class KakaoController < ApplicationController
  def keyboard
    if User.find_by(key: params[:user_key])
      p "유저가 있음"
    else
      p "노 유저"
      if User.create(key: params[:user_key])
        p "유저 생성됨"
      end
    end
    @keyboard = {
      type: "buttons",
      :buttons => ["사이트 리스트"]
    }
    
    render json: @keyboard
  end

  def message
    @user_msg = params[:content] #사용자의 입력값

    
    if @user_msg == "사이트 리스트"
      @cuser = User.find_by(key: params[:user_key])
      @usite = []
      @text = "[Site list]\n"
      
      @cuser.sites.each do |s|
        @usite.push(s.sname)
        # @text << s.sname << "\n"
      end
      @usite.push("[추가하기]")
      
    elsif @user_msg == "홈으로"
      @text = "홈으로 돌아왔다능.."
    elsif @user_msg == "PW 설정"
      @text = "보안 그 너머로.."
    else
      @text = "잘못된 입력이라능!"
    end
    
    @return_msg = {
      :text => @text
      }
    @return_keyboard = {
       type: "buttons",
      :buttons => ["사이트 리스트"]
      }
    @site_keyboard = {
      type: "buttons",
      buttons: @usite
    }
    
    if @user_msg == "사이트 리스트"
      @result = {
        :message => @return_msg,
        :keyboard => @site_keyboard
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

class KakaoController < ApplicationController
  def keyboard
    @keyboard = {
      type: "buttons",
      :buttons => ["사이트 리스트"]
    }
    
    render json: @keyboard
  end

  def message
    if User.find_by(key: params[:user_key])
      p "유저가 있음"
    else
      p "노 유저"
      if User.create(key: params[:user_key])
        p "유저 생성됨"
      end
    end
    
    @user_msg = params[:content] #사용자의 입력값
    @cuser = User.find_by(key: params[:user_key])
    @usite =  []
    
    @cuser.sites.each do |s|
      @usite.push(s.sname)
    end
    
    if @user_msg == "홈으로"
      @text = "홈으로 돌아왔다능.."
      @cuser.update(flag: 0)
    elsif @usite.include?(@user_msg)
      @text = "[" + @user_msg + "]\n"
      @text << "[ID] " + Site.find_by(sname: @user_msg).sid + "\n"
      @text << "[PW] " + Site.find_by(sname: @user_msg).spw + "\n"
    
    elsif @user_msg == "[직접입력]"
      @text = "사이트 이름을 입력 해 주세요"
      @cuser.update(flag: 1)
    elsif @cuser.flag == 0
      if @user_msg == "사이트 리스트"
        @text = "[Site list]\n"
        
        @usite.push("[추가하기]")
        
        if @cuser.sites.first
          @usite.push("[삭제하기]")
        end
      elsif @user_msg == "[추가하기]"
        @text = "아래에서 추가할 사이트를 선택하거나\n 직접 입력하세요"
        @cuser.update(flag: 1) 
      elsif @user_msg == "[삭제하기]"
        @text = "삭제 할 사이트를 선택 해 주세요"
        @cuser.sites.each do |s|
          @usite.push(s.sname)
        end
      else
        @text = "잘못된 입력이라능!"
      end
    elsif @cuser.flag == 1
      Site.create(sname: @user_msg, user: @cuser)
      @text = "["+ @user_msg + "]\n"+"거의 다 왔습니다.\n이젠 아이디를 입력 해 볼까요?"
      @cuser.update(flag: 2)# 아이디 입력 모드
      @cuser.sites.each do |s|
        @usite.push(s.sname)
      end
    elsif @cuser.flag == 2
      Site.where(user: @cuser).last.update(sid: @user_msg)
      @text = "["+ @user_msg + "]\n"+"마지막 단계입니다.\n패스워드를 입력 해 주세요"
      @cuser.update(flag: 3) # 비번 입력 모드 
    elsif @cuser.flag == 3
      Site.where(user: @cuser).last.update(spw: @user_msg)
      @text ="저장 되었습니다.\n사이트리스트로 돌아갑니다."
      @cuser.update(flag: 0)
    elsif @cuser.flag == -1 && Site.where(user: @cuser, sname: @user_msg).last
      Site.where(user: @cuser, sname: @user_msg).last.destroy
      @text = @user_msg + "\n사이트가 삭제되었습니다."
      @cuser.update(flag: 0)
    end
    
    @return_msg = {
      :text => @text
      }
    @return_keyboard = {
      type: "buttons",
      buttons: ['사이트 리스트']
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
    elsif @user_msg == "[추가하기]"
      @result = {
        message: @return_msg,
        keyboard: {
          type: "buttons",
          buttons: ["Naver", "Daum", "Gmail", "Facebook", "[직접입력]"]
        }
      }
    elsif @user_msg == "[삭제하기]"
      @usite << "홈으로"
      @result = {
        message: @return_msg,
        keyboard: {
          type: "buttons",
          buttons: @usite
        }
      }
      @cuser.update(flag: -1)
    elsif @user_msg == "[직접입력]"
      @cuser.update(flag: 1) # 사이트 이름 직접 입력 플래그 
      @result = {
        message: @return_msg
      }
    elsif @cuser.flag == 4
      #TODO
    elsif @cuser.flag? && @user_msg != "홈으로"
      @result = {
        message: @return_msg
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

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
    
    @msg_from_user = params[:content] #사용자의 입력값
    @talking_user = User.find_by(key: params[:user_key]) #Users 테이블에서 User 객체 하나를 찾는다.
    @user_own_site_list = [] #여러 개의 site 목록을 주고받을 수 있다.
    
    @talking_user.sites.each do |s|
      if not @user_own_site_list.include?(s.site_name)
        @user_own_site_list.push(s.site_name)
      end
    end
    #flag 란 버튼 띄우는 상태를 나타내는 것으로 보임  0이 홈으로 보임. 아니면 클라이언트가 위치한 상태를 나타내는듯
	#text 란 서버에서 클라이언트로 보낼 문자열
	#msg_from_user 란 클라이언트가 서버에 전달할 메세지 (주로 버튼 혹은 문자열 입력을 통해) 
# 1. 유저가 홈으로 버튼 눌렀을 때의 이벤트 // 주의 : 어느 상태에서나 무조건 홈으로 돌아오는 오류가 있음
	if @msg_from_user == "[홈으로]"
      @text = "홈으로 돌아왔다능.."
      @talking_user.update(flag: 0) 
# 2. 계정 정보 출력
    elsif @user_own_site_list.include?(@msg_from_user) && @talking_user.flag != -1 && @talking_user.flag != 1
      @text = "[" + @msg_from_user + "]\n\n"
      Site.where(user: @talking_user, site_name: @msg_from_user).each do |s|
        @text << "[ID] " + s.sid + "\n"
        @text << "[PW] " + s.spw + "\n"
        @text << "[Updated] " + s.updated_at.strftime('%Y년 %m월 %d일 %H:%M') + "\n\n"
      end
# 3. 사이트 이름을 직접 입력받음
    elsif @msg_from_user == "[직접입력]"
      @text = "사이트 이름을 입력 해 주세요\n되돌아 가려면 [홈으로]를 입력하세요"
      @talking_user.update(flag: 1)
# 4. flag : 0 => 홈 상태
    elsif @talking_user.flag == 0
	## 4-1. 사이트 리스트 버튼 클릭
      if @msg_from_user == "사이트 리스트"
        @text = "저장되는 정보는 관리자도 열람 할 수 없습니다.\n안심하고 이용하세요."
        
        @user_own_site_list.push("--------------------------------------------")
        @user_own_site_list.push("[추가하기]")
        
        if @talking_user.sites.first
          @user_own_site_list.push("[삭제하기]")
        end
		
	## 4-2. 추가하기 버튼 클릭했을 때의 이벤트
      elsif @msg_from_user == "[추가하기]"
        @text = "아래에서 추가할 사이트를 선택하거나\n 직접 입력하세요"
        @talking_user.update(flag: 1)
		
	## 4-3. 삭제하기 버튼 클릭했을 때의 이벤트
      elsif @msg_from_user == "[삭제하기]"
        @text = "삭제 할 사이트를 선택 해 주세요"
        @user_own_site_list = []
        
        @talking_user.sites.each do |s|
          @user_own_site_list.push(s.site_name + " --") #삭제할 리스트를 작성하기 위해 리스트에 사이트들을 차례로 push해준다.
        end
        
        @talking_user.update(flag: -1)
		
	## 4-4. 잘못된 입력????
      else
        @text = "잘못된 입력이라능!"
		
        @talking_user.update(flag: 0)
      end

# 5. flag : 1 / 사이트 선 생성 후 입력모드 -> flag : 2
    elsif @talking_user.flag == 1
      Site.create(site_name: @msg_from_user, user: @talking_user)
      @text = "["+ @msg_from_user + "]\n"+"이젠 아이디를 입력 해 볼까요?"
      @talking_user.update(flag: 2)# 아이디 입력 모드
      @talking_user.sites.each do |s|
        @user_own_site_list.push(s.site_name)
      end
# 6. flag : 2 / ID 입력 시나리오
    elsif @talking_user.flag == 2
      Site.where(user: @talking_user).last.update(sid: @msg_from_user)
      @text = "["+ @msg_from_user + "]\n"+"마지막 단계입니다.\n패스워드를 입력 해 주세요"
      @talking_user.update(flag: 3) 
# 7. flag : 3 / 계정 저장 액션
    elsif @talking_user.flag == 3
      Site.where(user: @talking_user).last.update(spw: @msg_from_user)
      @text ="저장 되었습니다.\n사이트리스트로 돌아갑니다."
      @talking_user.update(flag: 0)#그 후 다시 홈으로
# 8. flag : -1 / 사이트 삭제 액션
    elsif @talking_user.flag == -1 && Site.where(user: @talking_user, site_name: @msg_from_user).last
      Site.where(user: @talking_user, site_name: @msg_from_user).last.destroy
      @text = @msg_from_user + "\n사이트가 삭제되었습니다."
      @talking_user.update(flag: 0)  
    end
#------상태에 따른 액션 정의 ↑
#------클라이언트로 반응할 액션 정의 ↓

    @return_msg = {
      :text => @text  #@text 란 서버에서 클라이언트로 보낼 문자열
      }
    @return_keyboard = {
      type: "buttons",
      buttons: ['사이트 리스트']
      }
    @site_keyboard = {
      type: "buttons",
      buttons: @user_own_site_list #여러 개의 site 목록을 버튼형식으로 제시할 수 있다.
    }
    
    if @msg_from_user == "사이트 리스트"
      @result = {
        :message => @return_msg,
        :keyboard => @site_keyboard
      }
    elsif @msg_from_user == "[추가하기]"
      @result = {
        message: @return_msg,
        keyboard: {
          type: "buttons",
          buttons: ["[직접입력]","--------------------------------------------","[홈으로]"]
        }
      }
    elsif @msg_from_user == "[삭제하기]"
      @user_own_site_list << "[홈으로]"
      @result = {
        message: @return_msg,
        keyboard: {
          type: "buttons",
          buttons: @user_own_site_list
        }
      }
    elsif @msg_from_user == "[직접입력]"
      @talking_user.update(flag: 1) # 사이트 이름 직접 입력 플래그 
      @result = {
        message: @return_msg
      }
    elsif @talking_user.flag? && @msg_from_user != "[홈으로]"
      @result = {
        message: @return_msg
      }
    else
      @result = {
        :message => @return_msg,
        :keyboard => @return_keyboard
      }
    end
    
    render json: @result #변환된 JSON을 클라이언트로 전송
  end
end

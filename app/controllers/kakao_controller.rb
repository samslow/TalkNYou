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
      p "이미 DB에 존재하는 유저이다."
    else
      p "DB에 존재하지 않는 유저이므로 생성 시도 중 . . ."
      if User.create(key: params[:user_key])
        p "생성 성공"
      end
    end
    
    @msg_from_user = params[:content] #사용자의 입력값
    @talking_user = User.find_by(key: params[:user_key]) #Users 테이블에서 User 객체 하나를 찾는다.
    @user_own_site_list = [] #site 목록을 담는 리스트
    
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
      @text = "홈 메뉴로 복귀하였음."
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
        @text = "사이트 리스트입니다."
        
        @user_own_site_list.push("--------------------------------------------")
        @user_own_site_list.push("[추가하기]")
        
        if @talking_user.sites.first
          @user_own_site_list.push("[삭제하기]")
        end
		
	## 4-2. 추가하기 버튼 클릭했을 때의 이벤트 -> flag : 1
      elsif @msg_from_user == "[추가하기]"
        @text = "아래에서 추가할 사이트를 선택하거나\n 직접 입력하세요"
        @talking_user.update(flag: 1)
		
	## 4-3. 삭제하기 버튼 클릭했을 때의 이벤트 -> flag : -1
      elsif @msg_from_user == "[삭제하기]" #클라이언트가 홈 상태에서 삭제하기 버튼을 클릭한다면
        @text = "삭제 할 사이트를 선택 해 주세요" #이런 메세지를 띄우고
        @user_own_site_list = [] #리스트를 하나 선언한 다음에
        
        @talking_user.sites.each do |s| #삭제할 리스트를 작성하기 위해 클라이언트의 사이트 이름들을 방금 선언한 리스트에 넣어준다.
          @user_own_site_list.push(s.site_name + " --") 
        end
        
        @talking_user.update(flag: -1) #그 후에 클라이언트의 플래그를 -1로 바꾼다.
		
	## 4-4. 잘못된 입력???? 
      else
        @text = "잘못된 입력이므로 홈으로 돌아감."
        @talking_user.update(flag: 0)
      end
# 4. flag : 0 => 홈 상태 ( 끝 )
# 5. flag : 1 / 사이트 선 생성 후 입력모드 -> flag : 2
    elsif @talking_user.flag == 1
      Site.create(site_name: @msg_from_user, user: @talking_user)
      @text = "["+ @msg_from_user + "]\n"+"이젠 아이디를 입력 해 볼까요?"
      @talking_user.update(flag: 2)# 아이디 입력 모드
      @talking_user.sites.each do |s|
        @user_own_site_list.push(s.site_name)
      end
# 6. flag : 2 / ID 입력 시나리오 -> flag : 3
    elsif @talking_user.flag == 2
      Site.where(user: @talking_user).last.update(sid: @msg_from_user)
      @text = "["+ @msg_from_user + "]\n"+"마지막 단계입니다.\n패스워드를 입력 해 주세요"
      @talking_user.update(flag: 3) 
# 7. flag : 3 / 계정 저장 액션 -> flag : 0
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
    # A. 클라이언트가 사이트 리스트 버튼을 클릭했으면
    if @msg_from_user == "사이트 리스트"
      @result = {
        :message => @return_msg,
        :keyboard => @site_keyboard #응답은 이렇게 된다.
      }
	# B. 클라이언트가 (사이트) 추가하기 버튼을 클릭했으면
    elsif @msg_from_user == "[추가하기]"
      @result = {
        message: @return_msg,
        keyboard: { #응답은 이렇게 된다.
          type: "buttons",
          buttons: ["[직접입력]","--------------------------------------------","[홈으로]"]
        }
      }
	# C. B에서 클라이언트가 직접 입력 버튼을 클릭했으면
    elsif @msg_from_user == "[직접입력]"
      @talking_user.update(flag: 1) # 사이트 이름 직접 입력 플래그 
      @result = {
        message: @return_msg
      }
	# D. 클라이언트가 (사이트) 삭제하기 버튼을 클릭했으면
    elsif @msg_from_user == "[삭제하기]"
      @user_own_site_list << "[홈으로]"
      @result = {
        message: @return_msg,
        keyboard: { #응답은 이렇게 된다.
          type: "buttons",
          buttons: @user_own_site_list 
        }
      }
	# E. 
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
	#결국 result 는 보낼 json? 
  end
end

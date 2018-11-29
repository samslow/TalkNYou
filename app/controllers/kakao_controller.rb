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
    @button_list = [] #클라이언트에게 출력할 버튼들의 리스트
    
    def push_site_list #button_list 에 사이트 목록을 넣는다.
	 @talking_user.sites.each do |each_site|
	  # if not @button_list.include?(each_site.site_name)  #이 코드는 이전 스키마의 한계점인 중복사이트 가능성 때문인 것으로 추정
	  @button_list.push(each_site.site_name)
	  end
	 end

	 def push_string(any_string) #button_list 에 아무 문자열이나 넣는다.
	  if(any_string.kind_of?(String))
	   @button_list.push(any_string)
	  else
	   "문자열 말고 다른거 넣지 마세요."
	  end
	 end
    #flag 란 버튼 띄우는 상태를 나타내는 것으로 보임  0이 홈으로 보임. 아니면 클라이언트가 위치한 상태를 나타내는듯
	#text 란 서버에서 클라이언트로 보낼 문자열
	#msg_from_user 란 클라이언트가 서버에 전달할 메세지 (주로 버튼 혹은 문자열 입력을 통해) 

# MINE FLAG ENUM SET
FLAG_ENUM =
[ HOME_MENU = 0,					# F0 : 홈 메뉴
  PRINT_SITE_LIST = 10,			# F10 : 사이트 목록 출력
  ADD_SITE = 15,						# F15 : 사이트 추가
  UPDATE_SITE_NAME = 16,		# F16 : 사이트 이름 변경
  DELETE_SITE = 19,					# F19 : 삭제 (필요 없을수도 -> 누르자마자 지워버릴 수도 있음. 삭제의 경우 제약조건 없음)

  PRINT_ACCOUNT_LIST = 20,				# F20 : 계정 목록 출력
  PRINT_EACH_ACCOUNT = 21,			# F21 : 개별 계정 메뉴 출력
  ADD_ACCOUNT_AT_ID = 23,				# F23 : 계정 추가 중 ID 입력
  ADD_ACCOUNT_AT_PW = 24,			# F24 : 계정 추가 중 PW 입력
  ADD_ACCOUNT_AT_MEMO = 25,		# F25 : 계정 추가 중 MEMO 입력
  UPDATE_ACCOUNT_AT_ID = 26,		# F26 : 계정 정보 중 ID 변경
  UPDATE_ACCOUNT_AT_PW = 27,		# F27 : 계정 정보 중 PW 변경
  UPDATE_ACCOUNT_AT_MEMO = 28,	# F28 : 계정 정보 중 MEMO 변경
  DELETE_ACCOUNT = 29,					# F29 : 계정 삭제

  IDONTKNOW = 30 ]# F30 :  계정 추가 시 에러

################################
# MINE FLAG SET 에 따라 구현 ( 상태 오른쪽엔 전이될 수 있는 상태 표시 )
case @talking_user.flag
# F0 : 홈 메뉴 => 10
when HOME_MENU
if @msg_from_user == "사이트 리스트"
	@talking_user
    @text = "사이트 리스트입니다."
	push_site_list
    @button_list.push("[추가하기]")
    
    if @talking_user.sites.first
      @button_list.push("[삭제하기]")
    end
  
# F10 : 사이트 목록 출력
when 10

# F15 : 사이트 추가
when 10
# F16 : 사이트 이름 변경
when 10
# F19 : 삭제 (필요 없을수도 -> 누르자마자 지워버릴 수도 있음. 삭제의 경우 제약조건 없음)
when 10

# F20 : 계정 목록 출력
when 10
# F21 : 개별 계정 메뉴 출력
when 10
# F23 : 계정 추가 중 ID 입력
when 10
# F24 : 계정 추가 중 PW 입력
when 10
# F25 : 계정 추가 중 MEMO 입력
when 10
# F26 : 계정 변경 중 ID 변경
when 10
# F26 : 계정 변경 중 PW 변경
when 10
# F26 : 계정 변경 중 MEMO 변경
when 10
# F29 : 계정 삭제
when 10

# F30 :  계정 추가 시 에러
when 10
# UNDEFINED CASE => 무조건 홈으로
else 
	@talking_user.update(flag: 0)  
end
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
      buttons: @button_list #여러 개의 site 목록을 버튼형식으로 제시할 수 있다.
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
      @button_list << "[홈으로]"
      @result = {
        message: @return_msg,
        keyboard: { #응답은 이렇게 된다.
          type: "buttons",
          buttons: @button_list 
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

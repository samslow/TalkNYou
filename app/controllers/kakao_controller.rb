class KakaoController < ApplicationController

##############▼ 상수 집합 ▼##############
#상수 선언하는 방법 : 식별자를 대문자로.
#버튼을 통해 클라이언트에서 서버로 입력되는 명령 문자열 집합

	OP_TO_HOME = "[홈으로]"
	OP_PRINT_SITE_LIST = "[사이트 리스트 보기]"
	OP_ADD_SITE = "[사이트 추가]"
	OP_ADD_ACCOUNT = "[계정 추가]"
	OP_UPDATE_SITE_NAME = "[사이트 이름 변경]"
	OP_DELETE_SITE = "[사이트 삭제]"
	OP_INPUT_CANCEL = "-1"

# 여기서의 플래그 이름은 모두 이벤트가 일어난 이후를 설명한다.
# 예를 들어, F10 : 사이트 목록 출력은 이미 사이트 목록이 출력된 이후의 상태를 나타낸다.
	HOME_MENU=0					# F00 : 홈 메뉴
	PRINT_SITE_LIST=10			# F10 : 사이트 목록 출력
	ADD_SITE = 15						# F15 : 사이트 추가
	UPDATE_SITE_NAME = 16		# F16 : 사이트 이름 변경
	DELETE_SITE = 19					# F19 : 삭제 (필요 없을수도 -> 누르자마자 지워버릴 수도 있음. 삭제의 경우 제약조건 없음)

	PRINT_ACCOUNT_LIST = 20				# F20 : 계정 목록 출력
	PRINT_EACH_ACCOUNT = 21			# F21 : 개별 계정 메뉴 출력
	ADD_ACCOUNT = 22						# F22 : 계정 추가 시작
	ADD_ACCOUNT_AT_ID = 23				# F23 : 계정 추가 중 ID 입력
	ADD_ACCOUNT_AT_PW = 24			# F24 : 계정 추가 중 PW 입력
	ADD_ACCOUNT_AT_MEMO = 25		# F25 : 계정 추가 중 MEMO 입력
	UPDATE_ACCOUNT_AT_ID = 26		# F26 : 계정 정보 중 ID 변경
	UPDATE_ACCOUNT_AT_PW = 27		# F27 : 계정 정보 중 PW 변경
	UPDATE_ACCOUNT_AT_MEMO = 28	# F28 : 계정 정보 중 MEMO 변경
	DELETE_ACCOUNT = 29					# F29 : 계정 삭제

	IDONTKNOW = 30 	# F30 :  계정 추가 시 에러
##############▲ 상수 집합 ▲##############
##############▼ 함수 집합 ▼##############
	def keyboard #가장 처음 띄워줄 버튼
		@keyboard = {
		type: "buttons",
		:buttons => [OP_PRINT_SITE_LIST] #HOME_MENU 에서 처음 띄워줘야 할 버튼과 같다.
		}
		render json: @keyboard
	end

	def push_site_list #button_list 에 사이트 목록을 넣는다.
		@talking_user.sites.each do |each_site|
		# if not @button_list.include?(each_site.site_name)  #이 코드는 이전 스키마의 한계점인 중복사이트 가능성 때문인 것으로 추정
			push_string(each_site.site_name)
		end
	end
 
	def push_account_list(picked_site_name) #button_list 에 선택된 사이트 이름에 속하는 계정들의 목록을 넣는다.
		@talking_user.sites.each do |each_site|
		# if not @button_list.include?(each_site.site_name)  #이 코드는 이전 스키마의 한계점인 중복사이트 가능성 때문인 것으로 추정
			if each_site.site_name == picked_site_name
				each_site.accounts.each do |each_account|
					push_string(each_account.ID_name)
				end
			end
		end
	end
 
	def push_string(any_string) #button_list 에 아무 문자열이나 넣는다.
		if(any_string.kind_of?(String))
			@button_list.push(any_string)
		else
			"문자열 말고 다른거 넣지 마세요."
		end
	end

	def state_transition(now_state, to_be_state) #현재 상태와 전이될 상태를 체크하고 적절하면 전이 수행, 부적절하면 에러 띄우고 홈메뉴로.
		#근데 우선 일단은 바로 전이만 되게 한다.
		@talking_user.update(flag: to_be_state)
	end

	def to_home # F0 : 홈 메뉴로 돌아간다. 다만 호출 전에 진행 중인 작업을 정상적으로 종료할 것
			push_string(OP_PRINT_SITE_LIST)
			@talking_user.update(str_1: nil)
			@talking_user.update(str_2: nil)
			@talking_user.update(str_3: nil)
			@talking_user.update(str_4: nil)
			@talking_user.update(str_5: nil)
			state_transition(@talking_user.flag, HOME_MENU)
	end

	def message #이 메소드가 전부다.
		if User.find_by(key: params[:user_key])
			p "이미 DB에 존재하는 유저이다."
		else
			p "DB에 존재하지 않는 유저이므로 생성 시도 중 . . ."
			if User.create(key: params[:user_key])
				p "생성 성공"
			end
		end
	  #keyboard 메소드와 message 메소드는 기본적으로 필요하다. 
	  
		@msg_from_user = params[:content] 
#msg_from_user 란 클라이언트가 서버에 전달할 메세지 (주로 버튼 혹은 문자열 입력을 통해) 
		@talking_user = User.find_by(key: params[:user_key]) #Users 테이블에서 User 객체 하나를 찾는다.
#@talking_user.flag 란 대화중인 유저의 상태번호를 나타내는 정수
		@button_list = [] 
#@button_list 란 클라이언트에게 출력할 버튼들의 리스트
		@text = ""
#text 란 서버에서 클라이언트로 보낼 텍스트


#######▼상태에 따른 이벤트 처리 방법 기술▼#######
#코딩 템플릿 
#주의할 점: 상태마다 유효한 명령어가 다르다.	
#	case @talking_user.flag
##F xx : [현재 상태내용] => F yy : [전이될 상태내용]				# 표기법 F xx => F yy 이란?  xx 번 상태에서 yy 번 상태로 전이한다.
#	when [현재 상태 내용 1(영어)]
#		├	case @msg_from_user
#		├	when [OP_명령어 1] #메뉴가 정확히 주어졌을 경우 (예를 들어 사이트 추가나 계정 추가를 클릭했을 경우)
#		├	┼	(처리)
#		├	┼	(메세지 생성) [보낼 텍스트 및 버튼 리스트 추가]  (버튼은 push_**** 함수를 통해 추가한다.)
#		├	┴	(상태전이) state_transition(@talking_user.flag, [전이될 상태 내용(영어)])
#		├	when [OP_명령어 2] .....(처리, 메세지 생성, 상태전이).......
#		├	when [OP_명령어 3] .....(처리, 메세지 생성, 상태전이).......
#		├	when [OP_명령어 4] .....(처리, 메세지 생성, 상태전이).......
#		├	else #메뉴가 정확히 주어지지 않은 경우 (예를 들어 특정 계정이나 특정 사이트를 클릭했을 경우)  .....(처리, 메세지 생성, 상태전이).......
#		├		.....(처리, 메세지 생성, 상태전이).......
#		└	end
#	when [현재 상태 내용 2(영어)] ............
#	when [현재 상태 내용 3(영어)] ............
#	when [현재 상태 내용 4(영어)] ............
#	when [현재 상태 내용 5(영어)] ............
#	else
#	end

		case @talking_user.flag
# F00 : 홈 메뉴 => F10 : 사이트 목록 출력
		when HOME_MENU
			case @msg_from_user
			when OP_PRINT_SITE_LIST #-> 이 버튼을 클릭했을 때 띄워줘야 할 다음 텍스트와 버튼들은?
				@text = "사이트 리스트입니다.\n"
				@text = @text + "F00 -> F10"
				push_site_list()
				push_string(OP_ADD_SITE)
				push_string(OP_TO_HOME)
				state_transition(@talking_user.flag, PRINT_SITE_LIST)
			else
				@text = "F00 -> F00"
				to_home
			end
# F10 : 사이트 목록 출력
		when PRINT_SITE_LIST
			case @msg_from_user #타게팅할 사이트 이름이 입력됨
			when OP_TO_HOME
				@text = "F10 -> F00"
				to_home
			when OP_ADD_SITE
				@text = "새 사이트의 이름을 입력해주세요.\n"
				@text = @text + "F10 -> F15"
				state_transition(@talking_user.flag, ADD_SITE)
				#이후 키보드 입력을 기다린다. (버튼 추가 X)
			else #들어온 입력이 사이트 이름
				@text = @text + "F10 -> F20"
				push_account_list(@msg_from_user)
				#push_string(1.class.to_s) Object.to_s 는 string으로 캐스팅하는 함수
				push_string(OP_ADD_ACCOUNT)
				push_string(OP_UPDATE_SITE_NAME)
				push_string(OP_DELETE_SITE)
				push_string(OP_TO_HOME)
				@talking_user.update(str_1: @msg_from_user)
				state_transition(@talking_user.flag, PRINT_ACCOUNT_LIST)
			end
# F15 : 사이트 추가 (버튼이 아닌 텍스트로 입력받는다.)
		when ADD_SITE
			case @msg_from_user #추가될 사이트 이름이 입력됨
			when OP_INPUT_CANCEL
				@text = "사이트 추가 취소.\n"
				to_home
			else
				if @talking_user.sites.find_by(site_name: @msg_from_user) #이미 존재하면
					@text = "이미 존재하는 사이트라서 새로 추가하진 않았습니다.\n"
				else
					Site.create(site_name: @msg_from_user, user: @talking_user)
					@text = @msg_from_user + "추가 완료.\n"
				end
				@text = @text + "F15 -> F00"
				to_home
			end

# F16 : 사이트 이름 변경
		when UPDATE_SITE_NAME
			case @msg_from_user #바뀔 사이트 이름이 입력됨
			when OP_INPUT_CANCEL
				@text = "사이트 이름 변경 취소.\n"
				@text = @text + "F16 -> F00"
				to_home
			else
				if @talking_user.sites.find_by(site_name: @msg_from_user) #이미 존재하면
					@text = "이미 존재하는 사이트 이름이므로 변경하지 않았습니다.\n"
				else
					site_to_update = @talking_user.sites.find_by(site_name: @talking_user.str_1)
					before_name = site_to_update.site_name
					site_to_update.update(site_name: @msg_from_user)
					after_name = site_to_update.site_name
					@text = before_name + "에서 " + after_name + "로 사이트 이름 변경 완료.\n"
				end
				@text = @text + "F16 -> F00"
				to_home
			end
			
=begin
 (필요 없을수도 -> 누르자마자 지워버릴 수도 있음. 삭제의 경우 제약조건 없음)
		when DELETE_SITE
			case @msg_from_user
			when OP_TO_HOME
				push_string(OP_PRINT_SITE_LIST)
				state_transition(@talking_user.flag, HOME_MENU)
			else
				push_string(OP_PRINT_SITE_LIST)
				state_transition(@talking_user.flag, HOME_MENU)
			end
=end
# F20 : 계정 목록 출력 (str_1 에 입력된 사이트 이름을 저장하고 있는 상태임)
when PRINT_ACCOUNT_LIST
	case @msg_from_user #타게팅할 계정 ID_name이 입력됨
	when OP_ADD_ACCOUNT
		@text = "원랜 추가메뉴 띄워야대는데 일단 막아둠\n"
		@text << "F20 -> F00"
		to_home
	when OP_UPDATE_SITE_NAME
		@text = "바꿀 사이트 이름을 입력해주세요.\n"
		@text << "F20 -> F16"
		state_transition(@talking_user.flag, UPDATE_SITE_NAME)
		#이후 키보드 입력을 기다린다. (버튼 추가 X)
	when OP_DELETE_SITE
		# F19 : 사이트 삭제를 바로 구현한 후에 홈으로 간다.
		@text = "원랜 삭제해야대는데 일단 막아둠\n"
		@text << "F20 -> F00"
		to_home
	when OP_TO_HOME
		@text = "F20 -> F00"
		to_home
	else #ID_name 입력
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	end
=begin
# F21 : 개별 계정 메뉴 출력
when PRINT_EACH_ACCOUNT
	case @msg_from_user
	when OP_TO_HOME
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	else
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	end
# F22 : 계정 추가 시작
when ADD_ACCOUNT
	case @msg_from_user
	when OP_TO_HOME
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	else
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	end
# F23 : 계정 추가 중 ID 입력
when ADD_ACCOUNT_AT_ID
	case @msg_from_user
	when OP_TO_HOME
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	else
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	end
# F24 : 계정 추가 중 PW 입력
when ADD_ACCOUNT_AT_PW
	case @msg_from_user
	when OP_TO_HOME
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	else
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	end
# F25 : 계정 추가 중 MEMO 입력
when ADD_ACCOUNT_AT_MEMO
	case @msg_from_user
	when OP_TO_HOME
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	else
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	end
# F26 : 계정 변경 중 ID 변경
when UPDATE_ACCOUNT_AT_ID
	case @msg_from_user
	when OP_TO_HOME
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	else
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	end
# F26 : 계정 변경 중 PW 변경
when UPDATE_ACCOUNT_AT_PW
	case @msg_from_user
	when OP_TO_HOME
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	else
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	end
# F26 : 계정 변경 중 MEMO 변경
when UPDATE_ACCOUNT_AT_MEMO
	case @msg_from_user
	when OP_TO_HOME
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	else
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	end
# F29 : 계정 삭제
when DELETE_ACCOUNT
	case @msg_from_user
	when OP_TO_HOME
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	else
		push_string(OP_PRINT_SITE_LIST)
		state_transition(@talking_user.flag, HOME_MENU)
	end
=end
		else 
# UNDEFINED CASE => 무조건 홈으로
			case @msg_from_user
			when OP_TO_HOME
				to_home
			else
				to_home
			end
		end

#######▲상태에 따른 이벤트 처리 방법 기술▲#######
#######▼클라이언트에 보낼 메세지 (텍스트/버튼) 초기화▼#######
		@return_text = {
		 :text => @text
		 }
		@return_buttons = {
		 type: "buttons",
		 buttons: @button_list
		}
		@button_test = {
		 type: "buttons",
		buttons: ['test button']
		 }
#######▲클라이언트에 보낼 메세지 (텍스트/버튼) 초기화▲#######
#######▼클라이언트에 전송할 메뉴 선정▼#######
		if @button_list == []  #출력할 버튼이 없이 :message만 result에 담겠다는건 다음번엔 클라이언트로부터 문자열 직접 입력만 받겠다는 것
			@result = { 
			:message => @return_text #TEXT
			}
		else
			@result = {
			:message => @return_text, #TEXT
			:keyboard => @return_buttons #BUTTON
			}
		end
		render json: @result 
#######▲클라이언트에 전송할 메뉴 선정▲#######
	end #method message end
##############▲ 함수 집합 ▲##############
end #class end
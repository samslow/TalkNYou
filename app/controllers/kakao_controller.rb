class KakaoController < ApplicationController

	##############▼ 상수 집합 ▼##############
	#상수 선언하는 방법 : 식별자를 대문자로.
	#버튼을 통해 클라이언트에서 서버로 입력되는 명령 문자열 집합
	
		OP_TO_HOME = "◎p.홈으로"
		OP_PRINT_SITE_LIST = "◎p.사이트 리스트 보기"
		OP_ADD_SITE = "◎p.사이트 추가"
		OP_ADD_ACCOUNT = "◎p.계정 추가"
		OP_UPDATE_SITE_NAME = "◎p.사이트 이름 변경"
		OP_DELETE_SITE = "◎p.사이트 삭제"
		OP_TEST_RECURSIVE = "◎p.TEST BUTTON"
		OP_UPDATE_ID_NAME = "◎p.ID 변경"
		OP_UPDATE_PW = "◎p.PW 변경"
		OP_UPDATE_MEMO = "◎p.메모 변경"
		OP_DELETE_ACCOUNT = "◎p.계정 삭제"
		OP_INPUT_CANCEL = "-1"
	
		OP_RESTRICTED_ARRAY = [OP_TO_HOME, OP_PRINT_SITE_LIST, OP_ADD_SITE, 
			OP_ADD_ACCOUNT, OP_UPDATE_SITE_NAME, OP_DELETE_SITE, 
			OP_TEST_RECURSIVE, OP_UPDATE_ID_NAME,
			OP_UPDATE_PW, OP_UPDATE_MEMO, OP_DELETE_ACCOUNT]
	
		NOT_FOUND_SITE = -1
		NOT_FOUND_ACCOUNT = -2
	# 여기서의 플래그 이름은 모두 이벤트가 일어난 이후를 설명한다.
	# 예를 들어, F10 : 사이트 목록 출력은 이미 사이트 목록이 출력된 이후의 상태를 나타낸다.
		HOME_MENU=0					# F00 : 홈 메뉴
		PRINT_SITE_LIST=10			# F10 : 사이트 목록 출력
		ADD_SITE = 15						# F15 : 사이트 추가
		UPDATE_SITE_NAME = 16		# F16 : 사이트 이름 변경
		DELETE_SITE = 19					# F19 : 삭제 (필요 없을수도 -> 누르자마자 지워버릴 수도 있음. 삭제의 경우 제약조건 없음)
	
		PRINT_ACCOUNT_LIST = 20				# F20 : 계정 목록 출력
		PRINT_EACH_ACCOUNT = 21			# F21 : 개별 계정 메뉴 출력
		ADD_ACCOUNT_AT_ID = 23				# F23 : 계정 추가 중 ID 입력
		ADD_ACCOUNT_AT_PW = 24			# F24 : 계정 추가 중 PW 입력
		ADD_ACCOUNT_AT_MEMO = 25		# F25 : 계정 추가 중 MEMO 입력
		UPDATE_ACCOUNT_AT_ID = 26		# F26 : 계정 정보 중 ID 변경
		UPDATE_ACCOUNT_AT_PW = 27		# F27 : 계정 정보 중 PW 변경
		UPDATE_ACCOUNT_AT_MEMO = 28	# F28 : 계정 정보 중 MEMO 변경
	
		IDONTKNOW = 30 	# F30 :  계정 추가 시 에러
	##############▲ 상수 집합 ▲##############
	##############▼ 함수 집합 ▼##############
		def keyboard #가장 처음 띄워줄 버튼
			@keyboard = {
			type: "buttons",
			:buttons => [OP_PRINT_SITE_LIST] #HOME_MENU 에서 처음 띄워줘야 할 버튼과 같다.
			#서비스 출시 시엔 OP_TEST_RECURSIVE 를 반드시 초기 버튼 제공에서 빼야한다.
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
	 
		def get_account_by_site_name_and_ID_name(site_name_argument, id_name_argument) #ID_name_argument는 상수취급
			temp_site = get_site_by_site_name(site_name_argument)
			temp_account = temp_site.accounts.find_by(ID_name: id_name_argument) 
			if temp_account
				temp_account
			else
				NOT_FOUND_ACCOUNT
			end
		end
	
		def get_site_by_site_name(site_name_argument)
			temp_site = @talking_user.sites.find_by(site_name: site_name_argument)
			if temp_site #temp_site.class != NilClass (존재하는 사이트 이름)
				temp_site
			else
				NOT_FOUND_SITE
			end
		end
	
		def push_string(any_string) #button_list 에 아무 문자열이나 넣는다.
			if(any_string.kind_of?(String))
				@button_list.push(any_string)
			else
				"문자열 말고 다른거 넣지 마세요."
			end
		end
	
	
		def print_transition(to_be_state)
			@text << state_to_string(@talking_user.flag)
			@text << " -> "
			@text << state_to_string(to_be_state)
		end
	
		def state_to_string(state)
			str = ""
			str << "F" << state.to_s
			if state == 0
				str << "0"
			end
			str
		end
	
		def check_operation_invasion(string_argument) #입력받는 문자열이 명령어와 겹치는지 검사한다.
			result = false	
			OP_RESTRICTED_ARRAY.each {|operation|
				if string_argument == operation
					result = true #겹치면 true 반환
					@text << operation << " 명령어와 겹칩니다.\n"
				end					
			}
			result
		end
	
		def has_any_account(site_name_argument)
			temp_site = get_site_by_site_name(site_name_argument) 
			if Account.where(site: temp_site).last
				true
			else
				false
			end
		end
		
		def print_account_existence(site_name_argument)
			if has_any_account(site_name_argument)
				@text << site_name_argument << "에 저장하신 계정들입니다.\n"
			else
				@text << "아직 "<< site_name_argument << "에 저장하신 계정이 없습니다.\n"
			end
			@text << "어떤 작업을 수행하시겠습니까?"
		end	

		def has_any_site
			if Site.where(user: @talking_user).last
				true
			else
				false
			end
		end
		
		def print_site_existence
			if has_any_site
				@text << "저장하신 사이트들입니다.\n"
			else
				@text << "아직 저장하신 사이트가 없습니다.\n"
			end
			@text << "어떤 작업을 수행하시겠습니까?"
		end
	
		def state_transition(now_state, to_be_state) #현재 상태와 전이될 상태를 체크하고 적절하면 전이 수행, 부적절하면 에러 띄우고 홈메뉴로.
			#근데 우선 일단은 바로 전이만 되게 한다.
			@talking_user.update(flag: to_be_state)
		end
	
		def clear_user_strings
			@talking_user.update(str_1: nil)
			@talking_user.update(str_2: nil)
			@talking_user.update(str_3: nil)
			@talking_user.update(str_4: nil)
			@talking_user.update(str_5: nil)
		end
	
		def delete_account(site_name_argument, id_name_argument)
			temp_site = get_site_by_site_name(site_name_argument)
			Account.where(site: temp_site, ID_name: id_name_argument).last.destroy
		end
		
		def delete_site(site_name_argument)
			temp_site = get_site_by_site_name(site_name_argument)
			Account.where(site: temp_site).destroy_all
			Site.where(user: @talking_user, site_name: @talking_user.str_1).last.destroy
		end
	
		def to_home # F0 : 홈 메뉴로 돌아간다. 다만 호출 전에 진행 중인 작업을 정상적으로 종료할 것
			clear_user_strings
			push_string(OP_PRINT_SITE_LIST)
			#push_string(OP_TEST_RECURSIVE)
			@text << "홈으로 돌아갑니다.\n"
			print_transition(HOME_MENU)
			state_transition(@talking_user.flag, HOME_MENU)
		end
	
		def to_print_sites # F0 : 홈 메뉴로 돌아간다. 다만 호출 전에 진행 중인 작업을 정상적으로 종료할 것
			clear_user_strings
			push_site_list()
			push_string(OP_ADD_SITE)
			push_string(OP_TO_HOME)
			print_site_existence
			print_transition(PRINT_SITE_LIST)
			state_transition(@talking_user.flag, PRINT_SITE_LIST)
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
	
	
	####### ▼ 상태에 따른 이벤트 처리 방법 기술 ▼ #######
	
	#주의할 점	: 상태마다, 유효한 명령어가 다르고 @talking_user가 갖는 str들의 의미가 다르다..	
	#주의할 점	: push_string 메소드 등을 통해 버튼을 추가해주지 않으면 버튼이 아닌 문자열 직접 입력을 받는다.
	####### ▼ 코딩 템플릿 ▼ ####### 상태에 따른 이벤트 처리 방법 기술은 이 템플릿대로 작성되었음.
	#case @talking_user.flag
	#├───when 상태 A
	#│	F xx : A 상태에 대해 설명 (str_1 : ~~ , str_2 : ~~, ...) # 현재 상태에서 @talking_user의 str_n 들이 의미하는 것 (없을 수도 있음)
	#├───when 상태 B
	#│     ├───case @msg_from_user ## @msg_from_user의 의미를 적어둘 수 있음.
	#│     ├───when OP_PRINT_SITE_LIST ....## 이 경우가 반드시 필요한 이유 : 어떤 상태에서든 방 나갔다 들어오면 무조건 이 버튼을 선택하게 되어있기 때문에.
	#│     ├───when OP_명령 a #OP_명령 x 는 버튼이 분명히 존재할 경우 ( [계정 추가] 버튼처럼)
	#│     │     ├───(상황에 맞는 처리 루틴)
	#│     │     ├───(전이 메세지) print_transition(flag), push_string(string), @text << "~~" 등등
	#│     │     └───(상태전이) state_transition(flag from, flag to) #대신 to_home 이나 to_print_sites 처럼 메소드를 쓸 수도 있음
	#│     ├───when OP_명령 b ....
	#│     ├───when OP_명령 c ....
	#│     └───else .... #사용자가 만든 사이트 등 버튼이 명확히 주어지지 않은 경우 (예를 들어 특정 계정이나 특정 사이트를 클릭했을 경우)	
	#│			end
	#├───when 상태 C ....
	#├───when 상태 D ....
	#├───when 상태 E ....
	#└───else ....
	#	 end
	####### ▲ 코딩 템플릿 ▲ #######
	
			case @talking_user.flag
	# F00 : 홈 메뉴 => F10 : 사이트 목록 출력
			when HOME_MENU
				case @msg_from_user
				when OP_PRINT_SITE_LIST
					to_print_sites
				when OP_TEST_RECURSIVE
					@text << has_any_site.to_s
					to_home
				else
					to_home
				end
	# F10 : 사이트 목록 출력
			when PRINT_SITE_LIST
				case @msg_from_user # 1.명령 / 2.(버튼을 통해 선택된) 사이트 이름
				when OP_PRINT_SITE_LIST
					to_print_sites
				when OP_TO_HOME
					to_home
				when OP_ADD_SITE
					@text = "추가할 새 사이트의 이름을 입력해주세요.\n"
					print_transition(ADD_SITE)
					state_transition(@talking_user.flag, ADD_SITE)
				else # 2.버튼을 통해 선택된 사이트 이름
					@talking_user.update(str_1: @msg_from_user)
	
					push_account_list(@msg_from_user)
					push_string(OP_ADD_ACCOUNT)
					push_string(OP_UPDATE_SITE_NAME)
					push_string(OP_DELETE_SITE)
					push_string(OP_TO_HOME)
					print_account_existence(@msg_from_user)
					print_transition(PRINT_ACCOUNT_LIST)
					state_transition(@talking_user.flag, PRINT_ACCOUNT_LIST)
				end
	# F15 : 사이트 추가
			when ADD_SITE
				if check_operation_invasion(@msg_from_user) 
					to_home
				else
					case @msg_from_user # 1.(직접 입력받은) 추가할 사이트의 이름
					when OP_PRINT_SITE_LIST
						to_print_sites
					when OP_INPUT_CANCEL
						@text << "사이트 추가 작업을 취소했습니다.\n"
						to_home
					else
						temp_site = get_site_by_site_name(@msg_from_user)
						if temp_site != NOT_FOUND_SITE #이미 존재하면
							@text = "입력하신건 이미 존재하는 사이트 이름이라서 새로 추가하진 않았습니다.\n"
						else # 사이트 추가 수행
							Site.create(site_name: @msg_from_user, user: @talking_user)
							@text << "사이트" << @msg_from_user + " 추가 완료.\n"
						end
						to_home
					end
				end
	# F16 : 사이트 이름 변경 (str_1 : 사이트 이름)
			when UPDATE_SITE_NAME
				if check_operation_invasion(@msg_from_user) 
					to_home
				else
					case @msg_from_user # 1.(직접 입력받은) 변경할 사이트의 새 이름
					when OP_PRINT_SITE_LIST
						to_print_sites
					when OP_INPUT_CANCEL
						@text << "사이트 이름 변경 작업을 취소했습니다.\n"
						to_home
					else
						old_site_name = @talking_user.str_1
						new_site_name = @msg_from_user
						duplicate_check = get_site_by_site_name(new_site_name)
						if duplicate_check != NOT_FOUND_SITE
							@text << "입력하신건 이미 존재하는 사이트 이름이라서 변경하지 않았습니다.\n"
						else # 사이트 이름 변경 수행
							updating_site = get_site_by_site_name(old_site_name)
							updating_site.update(site_name: new_site_name)
							@text = old_site_name + "에서 " + new_site_name + "로 사이트 이름 변경 완료.\n"
						end
						to_home
					end
				end
				
	# F20 : 계정 목록 출력 (str_1 : 사이트 이름)
			when PRINT_ACCOUNT_LIST
				case @msg_from_user # 1.명령 / 2.(버튼을 통해 선택된) 계정의 ID_name
				when OP_PRINT_SITE_LIST
					to_print_sites
				when OP_ADD_ACCOUNT
					@text << "추가할 ID는?\n"
					print_transition(ADD_ACCOUNT_AT_ID)
					state_transition(@talking_user.flag, ADD_ACCOUNT_AT_ID)
				when OP_UPDATE_SITE_NAME 
					@text << "새로운 사이트 이름을 입력해주세요.\n"
					print_transition(UPDATE_SITE_NAME)
					state_transition(@talking_user.flag, UPDATE_SITE_NAME)
				when OP_DELETE_SITE
					# 사이트 삭제의 경우엔 별도의 상태를 두지 않고 바로 삭제를 실행한 후에 홈으로 간다.
					delete_site(@talking_user.str_1)
					to_home
				when OP_TO_HOME
					to_home
				else #ID_name 선택
					picked_account = get_account_by_site_name_and_ID_name(@talking_user.str_1, @msg_from_user)
					if picked_account == NOT_FOUND_ACCOUNT
						@text << "계정을 찾을 수 없음\n" #있을 수 없는 상황임
						to_home
					else
						@text << "ID.  " << picked_account.ID_name << "\n"
						@text << "PW.  " << picked_account.PW << "\n"
						@text << "메모.  " << picked_account.memo << "\n"
						@text << "최종 업데이트 시각.\n" << picked_account.updated_at.strftime('%Y년 %m월 %d일 %H:%M') << "\n"
						@talking_user.update(str_2: @msg_from_user)
	
						push_string(OP_UPDATE_ID_NAME)
						push_string(OP_UPDATE_PW)
						push_string(OP_UPDATE_MEMO)
						push_string(OP_DELETE_ACCOUNT)
						push_string(OP_TO_HOME)
						print_transition(PRINT_EACH_ACCOUNT)
						state_transition(@talking_user.flag, PRINT_EACH_ACCOUNT)
					end
				end
			# F21 : 개별 계정 메뉴 출력 (str_1 : 사이트 이름, str_2 : ID_name)
			when PRINT_EACH_ACCOUNT
				case @msg_from_user # 1.명령
				when OP_PRINT_SITE_LIST
					to_print_sites
				when OP_UPDATE_ID_NAME
					@text << "변경할 ID는?\n"
					print_transition(UPDATE_ACCOUNT_AT_ID)
					state_transition(@talking_user.flag, UPDATE_ACCOUNT_AT_ID)
				when OP_UPDATE_PW
					@text << "변경할 PW는?\n"
					print_transition(UPDATE_ACCOUNT_AT_PW)
					state_transition(@talking_user.flag, UPDATE_ACCOUNT_AT_PW)
				when OP_UPDATE_MEMO
					@text << "변경할 메모는?\n"
					print_transition(UPDATE_ACCOUNT_AT_MEMO)
					state_transition(@talking_user.flag, UPDATE_ACCOUNT_AT_MEMO)
				when OP_DELETE_ACCOUNT	
					delete_account(@talking_user.str_1, @talking_user.str_2)
					to_home
				when OP_TO_HOME
					to_home
				else
					to_home
				end
			# F23 : 계정 추가 중 ID 입력 (str_1 : 사이트 이름)
			when ADD_ACCOUNT_AT_ID
				if check_operation_invasion(@msg_from_user) 
					to_home
				else
					case @msg_from_user # 1.(직접 입력받은) 추가할 계정의 ID_name
					when OP_PRINT_SITE_LIST
						to_print_sites
					when OP_INPUT_CANCEL
						@text << "계정 추가 취소.\n"
						to_home
					else
						site_to_attach_account = @talking_user.sites.find_by(site_name: @talking_user.str_1)
						if (site_to_attach_account.accounts.find_by(ID_name: @msg_from_user))
							@text << "중복된 ID 가 이미 있습니다.\n"
							@text << "추가할 ID 를 다시 입력해주세요.\n"
							print_transition(ADD_ACCOUNT_AT_ID)
							state_transition(@talking_user.flag, ADD_ACCOUNT_AT_ID)
						else #계정 추가 계속 진행
							@talking_user.update(str_2: @msg_from_user)
							@text = "추가할 PW는?\n"
							print_transition(ADD_ACCOUNT_AT_PW)
							state_transition(@talking_user.flag, ADD_ACCOUNT_AT_PW)
						end
					end
				end
			# F24 : 계정 추가 중 PW 입력 (str_1 : 사이트 이름, str_2 : 새 ID_name)
			when ADD_ACCOUNT_AT_PW
				if check_operation_invasion(@msg_from_user) 
					to_home
				else
					case @msg_from_user	# 1.(직접 입력받은) 추가할 계정의 PW
					when OP_PRINT_SITE_LIST
						to_print_sites
					when OP_INPUT_CANCEL
						@text << "계정 추가 취소.\n"
						to_home
					else #PW와 memo 입력은 중복체크가 필요없다.
						@talking_user.update(str_3: @msg_from_user)
						@text << "추가할 메모는?\n"
						print_transition(ADD_ACCOUNT_AT_MEMO)
						state_transition(@talking_user.flag, ADD_ACCOUNT_AT_MEMO)
					end
				end
			# F25 : 계정 추가 중 memo 입력 (str_1 : 사이트 이름, str_2 : 새 ID_name, str_3 : 새 PW)
			when ADD_ACCOUNT_AT_MEMO
				if check_operation_invasion(@msg_from_user) 
					to_home
				else
					case @msg_from_user	# 1.(직접 입력받은) 추가할 계정의 memo
					when OP_PRINT_SITE_LIST
						to_print_sites
					when OP_INPUT_CANCEL
						@text = "계정 추가 취소.\n"
						to_home
					else #메모까지 전부 입력받았을 때야 비로소 @talking_user 의 문자열들을 조합하여 새로운 계정을 만든다.
						@talking_user.update(str_4: @msg_from_user)
						site_to_attach_account = @talking_user.sites.find_by(site_name: @talking_user.str_1)
						Account.create(ID_name: @talking_user.str_2, PW: @talking_user.str_3, memo:@talking_user.str_4, site: site_to_attach_account)
						@text << "계정 추가 성공.\n"
						to_home
					end
				end
				
			# F26 : 계정 변경 중 ID 변경 (str_1 : 사이트 이름, str_2 : ID_name)
			when UPDATE_ACCOUNT_AT_ID
				if check_operation_invasion(@msg_from_user) 
					to_home
				else
					case @msg_from_user	# 1.(직접 입력받은) 변경할 계정의 새 ID_name
					when OP_PRINT_SITE_LIST
						to_print_sites
					when OP_INPUT_CANCEL
						@text << "계정 ID 변경 취소.\n"
						to_home
					else
						site_name = @talking_user.str_1
						old_id_name = @talking_user.str_2
						new_id_name = @msg_from_user
						duplicate_check = get_account_by_site_name_and_ID_name(site_name, new_id_name)
						if duplicate_check != NOT_FOUND_ACCOUNT # 입력받은 ID 가 이미 존재하면
							@text << "이미 " + site_name + " 내에 동일한 ID 가 존재하므로 변경하지 않았습니다.\n"
						else 
							updating_account = get_account_by_site_name_and_ID_name(site_name, old_id_name)
							updating_account.update(ID_name: new_id_name)
							@text << old_id_name + "에서 " + new_id_name + "로 ID 변경 완료.\n"
						end
						to_home
					end
				end
			# F27 : 계정 변경 중 PW 변경 (str_1 : 사이트 이름, str_2 : ID_name)
			when UPDATE_ACCOUNT_AT_PW
				if check_operation_invasion(@msg_from_user) 
					to_home
				else
					case @msg_from_user	# 1.(직접 입력받은) 변경할 계정의 새 PW
					when OP_PRINT_SITE_LIST
						to_print_sites
					when OP_INPUT_CANCEL
						@text << "계정 PW 변경 취소.\n"
						to_home
					else
						site_name = @talking_user.str_1
						id_name = @talking_user.str_2
						updating_account = get_account_by_site_name_and_ID_name(site_name, id_name)
						old_pw = updating_account.PW
						new_pw = @msg_from_user
						updating_account.update(PW: new_pw)
						@text << old_pw + "에서 " + new_pw + "로 PW 변경 완료.\n"
						to_home
					end
				end
			# F28 : 계정 변경 중 MEMO 변경 (str_1 : 사이트 이름, str_2 : ID_name)
			when UPDATE_ACCOUNT_AT_MEMO
				if check_operation_invasion(@msg_from_user) 
					to_home
				else
					case @msg_from_user	# 1.(직접 입력받은) 변경할 계정의 새 memo
					when OP_PRINT_SITE_LIST
						to_print_sites
					when OP_INPUT_CANCEL
						@text << "계정 memo 변경 취소.\n"
						to_home
					else
						site_name = @talking_user.str_1
						id_name = @talking_user.str_2
						updating_account = get_account_by_site_name_and_ID_name(site_name, id_name)
						old_memo = updating_account.memo
						new_memo = @msg_from_user
						updating_account.update(memo: new_memo)
						@text << old_memo + "에서 " + new_memo + "로 PW 변경 완료.\n"
						to_home
					end
				end
			else 
			# UNDEFINED CASE => 무조건 홈으로
				case @msg_from_user # 1.명령
				when OP_PRINT_SITE_LIST
					to_print_sites
					@text << "현재 상태가 정의되지 않았음." #여기가 실행될 리는 없음
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
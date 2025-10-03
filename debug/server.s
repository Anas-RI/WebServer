.intel_syntax	noprefix
.global		_start

.section .text

_start:
	# SOCKET
	mov	rdi, 2			# int domain
	mov	rsi, 1			# int type
	mov	rdx, 0			# int protocol
	mov	rax, 0x29
	syscall

	# BIND
	mov	r15, rax		# save sockfd
	mov	rdi, r15		# int sockfd
	lea	rsi, [rip + sockaddr]	# struct sockaddr* addr
	mov	rdx, 16			# int addrlen
	mov	rax, 0x31
	syscall

	# LISTEN
	mov	rdi, r15		# int sockfd
	mov	rsi, 0			# int backlog
	mov	rax, 0x32
	syscall

	serverLoop:
		# ACCEPT
		mov	rdi, r15		# int sockfd
		mov	rsi, 0			# struct sockaddr* addr
		mov	rdx, 0			# int* addrlen
		mov	rax, 0x2B
		syscall
	
		# FORK
		mov	r14, rax
		mov	rax, 0x39
		syscall
	
		cmp	rax, 0
		je	_child
	
		# CLOSE
		mov	rdi, r14		# unsigned int fd
		mov	rax, 0x03
		syscall

	jmp	serverLoop
_child:
	# CLOSE
	mov	rdi, r15
	mov	rax, 0x03
	syscall

	mov	r15, r14		# Client fd

	mov	r8, rsp			# address of buf in stack
	# READ
	mov	rdi, r15		# unsigned int fd
	mov	rsi, r8			# char* buf
	mov	rdx, 512		# size_t count
	mov	rax, 0x00
	syscall

	# PARSER
	mov	rdi, r8
	call	parseReq

	#	rdi:	temp filename
	#	rsi:	0 || post length pointer
	#	rax:	4 == GET ||  5 == POST

#	#################################### DEGUB
#	mov	r14, rsi
#
#	mov	rdi, 1
#	mov	rsi, r14
#	mov	rdx, 64
#	mov	rax, 0x01
#	nop
#	syscall
#	#################################### DEGUB

	cmp	rax, 5
	je	postReq
	cmp	rax, 4
	je	getReq
	jmp	_exit

# POST /tmp/tmpduchpjsn\0HTTP/1.1\r\nHost: localhost\r\nUser-Agent: python-requests/2.32.4\r\nAccept-Encoding: gzip, deflate, zstd\r\nAccept: */*\r\nConnection: keep-alive\r\nContent-Length: 36\r\n\r\nSIWlgPYg8w7njYDeOHW9W4Zl4kAGu2HnxPxP

postReq:
	mov	r8, rdi			# POST filename
	mov	r9, rsi			# POST length pointer

	# POST DATA
	mov	rdi, r9
	call	postContent
	cmp	rax, 0
	je	_exit

	mov	r9, rdi			# POST data pointer
	mov	r10, rax		# POST data length

	# OPEN
	mov	rdi, r8			# const char* filename
	mov	rsi, 0x41		# int flags
	mov	rdx, 0777		# umode_t mode
	mov	rax, 0x02
	syscall

	mov	r8, rax			# Temp file fd

	# WRITE TO FILE
	mov	rdi, r8			# fd
	mov	rsi, r9			# buf
	mov	rdx, r10		# size
	mov	rax, 0x01
	syscall

	# CLOSE TMP FILE
	mov	rdi, r8			# unsigned int fd
	mov	rax, 0x03
	syscall

	# WRITE
	mov	rdi, r15
	lea	rsi, [rip + reply]
	mov	rdx, 19
	mov	rax, 0x01
	syscall

	jmp	_exit

# GET /tmp/tmpos3un4co HTTP/1.1\r\nHost: localhost\r\nUser-Agent: python-requests/2.32.4\r\nAccept-Encoding: gzip, deflate, zstd\r\nAccept: */*\r\nConnection: keep-alive\r\n\r\n

getReq:
	mov	r8, rdi			# GET filename

	# OPEN
	mov	rdi, r8			# const char* filename
	mov	rsi, 0			# int flags
	mov	rdx, 0			# umode_t mode
	mov	rax, 0x02
	syscall

	mov	r8, rax			# tmp fd

	# READ
	mov	rdi, r8			# fd
	mov	rsi, rsp		# buff
	mov	rdx, 512		# size
	mov	rax, 0x00
	syscall

	mov	r9, rax			# read count

	# CLOSE
	mov	rdi, r8
	mov	rax, 0x03
	syscall

	mov	r8, r9			# read count && free r9

	# WRITE
	mov	rdi, r15
	lea	rsi, [rip + reply]
	mov	rdx, 19
	mov	rax, 0x01
	syscall

	# WRITE
	mov	rdi, r15
	mov	rsi, rsp
	mov	rdx, r8
	mov	rax, 0x01
	syscall

	jmp	_exit

_exit:
	# EXIT
	mov	rdi, 0			# int error_code
	mov	rax, 0x3C
	syscall

# int	parseReq(char *str)
parseReq:
	parseGet:
		lea	rsi, [rip + getstr]
		mov	rdx, 4
		call	strncmp
		cmp	rax, -1
		jne	parseFile
	parsePost:
		lea	rsi, [rip + poststr]
		mov	rdx, 5
		call	strncmp
		cmp	rax, -1
		je	parseFail
		jmp	parseFile
	parseFail:
		mov	rdx, -1
		jmp	parseRet
	parseFile:
		lea	rdi, [rdi + rdx]
		filename:
			inc	rdi
			cmp	BYTE PTR [rdi], 0x20
			jne	filename
		mov	BYTE PTR [rdi], 0x00
		mov	rsi, 0
		cmp	rdx, 5
		jne	parseRet
		lea	rsi, [rdi + 155]
	parseRet:
		lea	rdi, [r8 + rdx]
		mov	rax, rdx
		ret

# int	strncmp(char* str1, char* str2, int size)
strncmp:
	mov	rax, 0
	mov	rcx, 0
	strncmp_loop:
		cmp	rcx, rdx
		jge	strncmp_done
		mov	r13b, BYTE PTR [rdi + rcx]
		mov	r14b, BYTE PTR [rsi + rcx]
		cmp	r13, r14
		jne	strncmp_fail
		inc	rcx
		jmp	strncmp_loop
	strncmp_fail:
		mov	rax, -1
	strncmp_done:
		ret

# char* postContent(char* str)
postContent:
	call	atoi
	lea	rdi, [rdi + 4]	# Skip \r\n\r\n
	ret			# Return rsi = POST data
				#	 rax = data length

# Description: Simple atoi func that gathers number from str until the first occurrence of '\'
# Return: integer
# int	atoi(char* str)
atoi:
	mov	rax, 0
	mov	r14, 10
	atoiLoop:
		mov	r13b, BYTE PTR [rdi]
		cmp	r13b, 0x0D
		je	atoiRet
		cmp	r13b, 0x00
		je	atoiRet
		sub	r13, 0x30
		mul	r14
		add	rax, r13
		inc	rdi
		jmp	atoiLoop
	atoiRet:
		ret

.section .data

sockaddr:
	.2byte 2	# AF_INET
	.2byte 0x5000	# Port 80
	.4byte 0	# Address 0.0.0.0
	.8byte 0	# 8 bytes for padding

reply:
	.string "HTTP/1.0 200 OK\r\n\r\n"

poststr:
	.string "POST "

getstr:
	.string "GET "


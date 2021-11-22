;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                   ;;
;;                      可显字符通用解码程序头                       ;;
;;                           Made By Adly                            ;;
;;                     2008-01-08 ~ 2012-11-05                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.model small
.code
start:

;	org 100h

; Start of Decode Engine
	and ax, 4040h
	and ax, 3030h		; ax = 0
	push ax			; 栈中存0
	xor ax, 302fh
	push ax
	pop di			; mov di, 302fh
				; 这里设置di初始值为 302fh
				; 标识后面是否需要动态解码
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; *** 需要手动修改的地址 ***
	; mov ax, 249h 的替代指令
	; 执行后，ax = 249h; 即指向待解码字符串
	pop ax			; 将栈中的0取出
	xor ax, 3278h
	xor ax, 3031h		; ax =  249h
;	dec ax			; ax = 41ffh
;	xor ax, 40bfh		; ax =  140h
;	mov ax, 223h
	
	; mov bx, ax 的替代指令
	push ax
	pop bx
	
	
NextWord:
	inc di			; 标志加一
	
	; 取两个字节
	; mov dx, [bx] 替代指令
	and ax, 4040h
	and ax, 3030h		; ax = 0
	push ax			; 将0存入栈中
	push ax
	pop si			; si = 0
	
	xor si, [bx]
	push si
	pop dx
	
	; cl = 4;
	pop ax			; 取出栈中的0
	inc ax
	inc ax
	inc ax
	inc ax			; ax = 4
	push ax
	pop cx			; cx = 4
	
	; mov ax, dx 替代指令
	push dx
	pop ax
	
	; cmp ax, 2121h 替代指令
	xor ax, 2121h		; 检测是否解码完成
	; *** 注意 ***
	; 下面的jz机器码编译后
	; 可能会被jnz/jmp指令替换
	; 造成机器指令非可显字符
	jz BridgeEndOfEngine	; 解码完成，则解码结束
				; 此位置的机器码
				; 注意EndOfEngine前面的填充符长度
				; 若机器码不在可显字符范围
				; 可以通过填充码来调整
				; 先通过中继来跳到程序结束处
	
	; 开始解码操作
	; 此时 dx = 待解码数据
	; shl al, cl		; 生成机器码 D2 E0 -> E0D2
	and ax, 4040h
	and ax, 3030h		; ax = 0
	push ax			; 栈中存入0
	dec ax			; ax = 0ffffh
	xor ax, 336fh		; ax = 0cc90h
	xor ax, 2c42h		; ax = 0e0d2h	; 机器码生成成功
	
	; 将生成的机器码放到 si
	push ax
	pop si
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; *** 需要手动修改的地址 ***
	; 准备修改 sp 指向 MagicCode -> 174h
	; 此地址为 30h, 30h 后面的地址
	pop ax			; 取出栈中的0
	xor ax, 3134h		; ax = 3134h
	xor ax, 3040h		; ax =  174h
	push ax
	pop sp
	push si
	
	; ax = dx 然后执行生成的 shl al, cl 指令
	push dx
	pop ax
	
	; jmp MagicCode 替代指令
	jz MagicCode1
	jnz MagicCode1
	
	db 21h dup(40h)		; 临时栈，主要为了使 jz/jnz 的机器码为可显字符
MagicCode1:
	db 30h, 30h		; 这里将被替换为 D2 E0 并被执行
				; 即 shl al, cl 的机器码
	
	; 此时 ax = 3xx0h
	; 使 al 存放解码后的字符
	push ax
	pop cx			; mov cx, ax
	push cx
	push cx
	inc sp
	pop ax
	inc sp
	xor ax, 3030h		; 此时 al = 0xh; cl = x0h
	
	push bx			; 保存 bx
	push cx			; 将待异或的值存入临时栈
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; *** 需要手动修改的地址 ***
	; 设置 bx = 130h
	push ax			; 保存ax
	and ax, 4040h
	and ax, 3030h		; ax = 0
	xor ax, 3170h		; ax = 3170h
	xor ax, 3040h		; ax =  130h
	push ax
	pop bx			; mov bx, ax; bx = 130h
	pop ax			; 恢复ax
	xor ax, [bx + 3eh]	; 存取 16eh 位置
				; 此地址值为 MagicCode - 6
	
	pop cx			; 栈平衡
	pop bx			; 恢复 bx
	
	; 显示字符
	; mov dl, al 替代指令
	push ax
	pop dx
	
	; 检测是否需要解码
	push di
	pop ax
	xor ax, 3030h
	jnz DontDecodeInt
	
	push ax			; 保存ax
	and ax, 4040h
	and ax, 3030h		; ax = 0
	push ax
	pop si			; si = 0
	pop ax			; 还原ax
BridgeEndOfEngine:
	push si
	pop ax
	xor ax, 2121h		; 检测是否因为需要解码才进入的
	jz EndOfEngine		; 不解码，为退出条件
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; *** 需要手动修改的地址 ***
	; 动态生成 int 21h 指令机器码
	; int 21h 地址 1a0h
	; 设置 bx = 170h
	push bx			; 保存 bx
	and ax, 4040h
	and ax, 3030h		; ax = 0
	push ax			; 栈中存入0
	xor ax, 3130h
	xor ax, 3040h		; ax = 170
	push ax
	pop bx			; mov bx, ax
	pop ax			; 取出栈中的0
	xor ax, 7130h
	xor ax, 3030h		; ax = 4100h
	dec ax			; ax = 40ffh 异或下面的 32h, 61h后，刚好形成int 21h的机器指令
	xor [bx + 69h], ax	; 修正 int 21h 码
				; bx + x 应该为下面 32h, 61h 的地址
				; 1d9h
	push bx
	pop cx			; mov cx, bx
	pop bx			; 恢复 bx

	
DontDecodeInt:
	
	; mov ah, 2h 替代指令
	and ax, 4040h
	and ax, 3030h		; ax = 0
	xor ax, 3230h
	xor ax, 3030h		; ax = 200h
	
	; CD 21          INT     21
	;int 21h
	db 32h, 61h
	
	inc bx			; 解码下一字节
	inc bx
	
	; 检测是否需要解码
	push di
	pop ax
	xor ax, 3030h
	jnz DontDecodeJmp
	db 10h dup(40h)
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; *** 需要手动修改的地址 ***
	; 动态生成 jmp NextWord 指令机器码
	; jmp NextWord 地址 216h
	; 设置 bx = 1c0h
	push bx			; 保存 bx
	and ax, 4040h
	and ax, 3030h		; ax = 0
	push ax			; 栈中存入0
	xor ax, 7230h
	xor ax, 3030h		; ax = 4200h
	dec ax			; ax = 41ffh
	xor ax, 403fh		; ax =  1c0h
	push ax
	pop bx			; mov bx, ax
	pop ax			; 取出栈中的0
	dec ax			; ax = 0ffffh
	xor ax, 7777h		; ax = 8888h
	xor [bx + 56h], ax	; 修正 jmp NextWord 码
				; bx + x 应该为下面 61h, 2dh 的地址
	xor [bx + 58h], al
	push bx
	pop cx			; mov cx, bx
	pop bx			; 恢复 bx

DontDecodeJmp:
	;jmp NextWord		; 对下一个字进行解码
	; E9 FC FE
	db 61h, 74h, 76h	; 分别与 88h, 88h, 88h 异或

; End of Decode Engine

EndOfEngine:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	and ax, 4040h
	and ax, 3030h		; ax = 0
	xor ax, 7c30h
	xor ax, 3030h		; ax = 4c00h
	
	;int 21h			; 程序退出码 0
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; *** 需要手动修改的地址 ***
	; 动态生成 int 21h 指令机器码
	; int 21h 地址 221h
	; 设置 bx = 200h
	push ax			; 保存 ax
	and ax, 4040h
	and ax, 3030h		; ax = 0
	xor ax, 3230h
	xor ax, 3030h		; ax = 200h
	push ax
	pop bx			; mov bx, ax
	and ax, 4040h
	and ax, 3030h		; ax = 0
	xor ax, 7130h
	xor ax, 3030h		; ax = 4100h
	dec ax			; ax = 40ffh 异或下面的 32h, 61h后，刚好形成int 21h的机器指令
	xor [bx + 47h], ax	; 修正 int 21h 码
				; bx + x 应该为下面 32h, 61h 的地址
				; 247h
	push bx
	pop cx			; mov cx, bx
	pop ax			; 恢复 ax
	
	; CD 21          INT     21
	db 32h, 61h
	
RealCode:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 编码后的任意程序
	; 编码方式：一次取1字节，认为其低4位为有效符
	; 高4位必须为3(即0011b)
	; 如：34h 31h 即解码后为 41h，将显示字符'A'
	; 解码引擎一旦遇到 21h,21h，即认为解码完成
	db 34h, 31h, 34h, 32h, 33h, 30h
	db 36h, 31h, 36h, 32h, 33h, 30h
	db 34h, 31h, 34h, 32h, 33h, 30h
	db 36h, 31h, 36h, 32h, 33h, 30h
	db 34h, 31h, 34h, 32h, 33h, 30h
	db 33h, 30h, 33h, 31h, 33h, 32h
	db 21h,21h, 21h

	
end start
global _start

%macro PRINT 1
    push ecx
    mov ecx, %1
    call print_z
    pop ecx
%endmacro

section .data
banner db 10,' +========================================+',10,' |             BYTE BITES                 |',10,' |          .---------------.             |',10,' |         /  o   o   o   o  \            |',10,' |        |===================|           |',10,' |        | lettuce + burger  |           |',10,' |         \_________________/            |',10,' |          GOOD FOOD. GOOD MOOD.          |',10,' +========================================+',10,0
menu db 10,'1. Show food menu',10,'2. Add food to order',10,'3. View current order',10,'4. Checkout / pay',10,'5. Read saved receipts',10,'6. Cancel current order',10,'7. Exit',10,'Choose [1-7]: ',0
food_menu:
    db '',10
    db '                   BYTE BITES FOOD MENU',10
    db '',10
    db '+-----------------------------+  +-----------------------------+',10
    db '| 1. CHEESEBURGER - PHP 80    |  | 2. CHICKEN RICE - PHP 120   |',10
    db '|                             |  |                             |',10
    db '|        .------------.       |  |        ( )  ( )             |',10
    db '|       / o  o  o  o   \      |  |          .----.   __        |',10
    db '|      (________________)     |  |         /      \_/  )       |',10
    db '|      | ~~~~~~~~~~~~~~ |     |  |        (_______/ \_/        |',10
    db '|      |================|     |  |      /  .:.:.:.:.   \       |',10
    db '|       \______________/      |  |     (________________)      |',10
    db '|                             |  |                             |',10
    db '+-----------------------------+  +-----------------------------+',10
    db '',10
    db '+-----------------------------+  +-----------------------------+',10
    db '| 3. FRENCH FRIES - PHP 35    |  | 4. ICED TEA - PHP 25        |',10
    db '|                             |  |                             |',10
    db '|       | | || | | |          |  |                  /          |',10
    db '|       | | || | | |          |  |                 /           |',10
    db '|      _|_|_||_|_|_|_         |  |        .-------/-.          |',10
    db '|      \            /         |  |        | []  / []|          |',10
    db '|       |  FRIES   |          |  |        |~~~~~~~~~|          |',10
    db '|        \________/           |  |         \       /           |',10
    db '|                             |  |          \_____/            |',10
    db '+-----------------------------+  +-----------------------------+',10
    db '',10
    db 0
item_prompt db 'Food ID [1-4], or 0 to go back: ',0
qty_prompt db 'Quantity to add [1-99], or 0 to go back: ',0
cash_prompt db 'Cash in whole PHP [1-1000000], or 0 to go back: ',0
confirm_prompt db 'Confirm payment? 1 = pay, 0 = go back: ',0
invalid db 'Invalid input. Enter digits within the requested range.',10,0
limit_msg db 'Maximum quantity is 99 per food item in one order.',10,0
added db 'Food added to your order.',10,0
empty_msg db 'Your order is empty. Add food first.',10,0
cancel_msg db 'Order cancelled. Nothing saved.',10,0
short_msg db 'Insufficient cash. Please try again.',10,0
back_msg db 'Payment cancelled. Your order is still available.',10,0
saved_msg db 'Payment recorded. Enjoy your meal!',10,0
save_error db 'Could not save receipt. Check receipts.txt before retrying:',10,'a partial or complete record may already exist. Order retained.',10,0
history_missing db 'No saved receipts yet.',10,0
history_error db 'Unable to open, read, or close receipts.txt.',10,0
bye db 'Thank you for visiting Byte Bites!',10,0
input_error db 'Input error. Exiting.',10,0
order_title db 10,'--- CURRENT ORDER ---',10,0
receipt_title db 10,'========== BYTE BITES RECEIPT ==========',10,0
receipt_end db '========================================',10,0
qty_label db ' x ',0
line_label db ' = PHP ',0
total_label db 'TOTAL: PHP ',0
cash_label db 'CASH: PHP ',0
change_label db 'CHANGE: PHP ',0
newline db 10,0
name1 db 'Cheeseburger',0
name2 db 'Chicken Rice',0
name3 db 'French Fries',0
name4 db 'Iced Tea',0
names dd name1,name2,name3,name4
prices dd 80,120,35,25
filename db 'receipts.txt',0

section .bss
cart resd 4
total resd 1
selected resd 1
cash resd 1
change resd 1
file_fd resd 1
receipt_len resd 1
receipt resb 1024
read_buffer resb 512
input_char resb 1
number_buffer resb 11

section .text
_start:
    cld
    PRINT banner
main_loop:
    PRINT menu
    call read_number
    cmp eax, -2
    je exit_ok
    cmp eax, 1
    je show_food
    cmp eax, 2
    je add_food
    cmp eax, 3
    je view_order
    cmp eax, 4
    je checkout
    cmp eax, 5
    je history
    cmp eax, 6
    je cancel_order
    cmp eax, 7
    je exit_ok
    PRINT invalid
    jmp main_loop
show_food:
    PRINT food_menu
    jmp main_loop

add_food:
    PRINT food_menu
.ask_item:
    PRINT item_prompt
    call read_number
    cmp eax, -2
    je exit_ok
    test eax, eax
    jz main_loop
    cmp eax, 1
    jl .bad_item
    cmp eax, 4
    jg .bad_item
    dec eax
    mov [selected], eax
    jmp .ask_qty
.bad_item:
    PRINT invalid
    jmp .ask_item
.ask_qty:
    PRINT qty_prompt
    call read_number
    cmp eax, -2
    je exit_ok
    test eax, eax
    jz main_loop
    cmp eax, 1
    jl .bad_qty
    cmp eax, 99
    jg .bad_qty
    mov ebx, [selected]
    mov edx, [cart+ebx*4]
    add edx, eax
    cmp edx, 99
    ja .limit
    mov [cart+ebx*4], edx
    imul eax, [prices+ebx*4]
    add [total], eax
    PRINT added
    jmp main_loop
.bad_qty:
    PRINT invalid
    jmp .ask_qty
.limit:
    PRINT limit_msg
    jmp .ask_qty

view_order:
    cmp dword [total], 0
    je empty_order
    PRINT order_title
    call build_items
    mov byte [edi], 0
    PRINT receipt
    jmp main_loop
empty_order:
    PRINT empty_msg
    jmp main_loop
cancel_order:
    call clear_cart
    PRINT cancel_msg
    jmp main_loop

checkout:
    cmp dword [total], 0
    je empty_order
    PRINT order_title
    call build_items
    mov byte [edi], 0
    PRINT receipt
.ask_cash:
    PRINT cash_prompt
    call read_number
    cmp eax, -2
    je exit_ok
    test eax, eax
    jz .back
    js .bad_cash
    cmp eax, [total]
    jb .short
    mov [cash], eax
    sub eax, [total]
    mov [change], eax
.confirm:
    PRINT confirm_prompt
    call read_number
    cmp eax, -2
    je exit_ok
    cmp eax, 0
    je .back
    cmp eax, 1
    je .save
    PRINT invalid
    jmp .confirm
.bad_cash:
    PRINT invalid
    jmp .ask_cash
.short:
    PRINT short_msg
    jmp .ask_cash
.back:
    PRINT back_msg
    jmp main_loop
.save:
    call build_receipt
    call save_receipt
    test eax, eax
    jnz .failed
    PRINT saved_msg
    PRINT receipt
    call clear_cart
    jmp main_loop
.failed:
    PRINT save_error
    jmp main_loop

history:
    call read_history
    jmp main_loop
exit_ok:
    PRINT bye
    mov eax, 1
    xor ebx, ebx
    int 0x80

clear_cart:
    xor eax, eax
    mov edi, cart
    mov ecx, 4
    rep stosd
    mov [total], eax
    mov [cash], eax
    mov [change], eax
    ret

read_number:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    xor esi, esi
    xor edi, edi
    xor ebp, ebp
.next:
    mov eax, 3
    xor ebx, ebx
    mov ecx, input_char
    mov edx, 1
    int 0x80
    cmp eax, -4
    je .next
    test eax, eax
    js .io_error
    jz .eof
    movzx eax, byte [input_char]
    cmp eax, 10
    je .finish
    cmp eax, '0'
    jb .bad
    cmp eax, '9'
    ja .bad
    test ebp, ebp
    jnz .next
    inc edi
    cmp edi, 7
    ja .bad
    sub eax, '0'
    imul esi, esi, 10
    add esi, eax
    cmp esi, 1000000
    ja .bad
    jmp .next
.bad:
    mov ebp, 1
    jmp .next
.eof:
    mov eax, -2
    test edi, edi
    jnz .finish
    test ebp, ebp
    jnz .finish
    jmp .done
.finish:
    mov eax, -1
    test ebp, ebp
    jnz .done
    test edi, edi
    jz .done
    mov eax, esi
.done:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
.io_error:
    PRINT input_error
    mov eax, 1
    mov ebx, 1
    int 0x80

write_all:
    push ecx
    push edx
.next:
    test edx, edx
    jz .success
    mov eax, 4
    int 0x80
    cmp eax, -4
    je .next
    test eax, eax
    js .done
    jz .zero_write
    add ecx, eax
    sub edx, eax
    jmp .next
.zero_write:
    mov eax, -5
    jmp .done
.success:
    xor eax, eax
.done:
    pop edx
    pop ecx
    ret

print_z:
    pushad
    xor edx, edx
.count:
    cmp byte [ecx+edx], 0
    je .write
    inc edx
    jmp .count
.write:
    mov ebx, 1
    call write_all
    test eax, eax
    js output_error
    popad
    ret
output_error:
    mov eax, 1
    mov ebx, 1
    int 0x80

append_z:
    push eax
    push esi
.next:
    lodsb
    test al, al
    jz .done
    stosb
    jmp .next
.done:
    pop esi
    pop eax
    ret

append_uint:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    mov esi, number_buffer+10
    mov byte [esi], 0
    mov ebx, 10
.convert:
    xor edx, edx
    div ebx
    add dl, '0'
    dec esi
    mov [esi], dl
    test eax, eax
    jnz .convert
    call append_z
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

append_items:
    xor ebp, ebp
.next:
    mov eax, [cart+ebp*4]
    test eax, eax
    jz .skip
    mov esi, [names+ebp*4]
    call append_z
    mov esi, qty_label
    call append_z
    call append_uint
    mov esi, line_label
    call append_z
    imul eax, [prices+ebp*4]
    call append_uint
    mov esi, newline
    call append_z
.skip:
    inc ebp
    cmp ebp, 4
    jb .next
    mov esi, total_label
    call append_z
    mov eax, [total]
    call append_uint
    mov esi, newline
    call append_z
    ret

build_items:
    mov edi, receipt
    call append_items
    ret

build_receipt:
    mov edi, receipt
    mov esi, receipt_title
    call append_z
    call append_items
    mov esi, cash_label
    call append_z
    mov eax, [cash]
    call append_uint
    mov esi, newline
    call append_z
    mov esi, change_label
    call append_z
    mov eax, [change]
    call append_uint
    mov esi, newline
    call append_z
    mov esi, receipt_end
    call append_z
    mov byte [edi], 0
    sub edi, receipt
    mov [receipt_len], edi
    ret

save_receipt:
    mov eax, 5
    mov ebx, filename
    mov ecx, 1089
    mov edx, 420
    int 0x80
    test eax, eax
    js .failed
    mov [file_fd], eax
    mov ebx, eax
    mov ecx, receipt
    mov edx, [receipt_len]
    call write_all
    test eax, eax
    js .close_failed
.sync:
    mov eax, 118
    mov ebx, [file_fd]
    int 0x80
    cmp eax, -4
    je .sync
    test eax, eax
    js .close_failed
    mov eax, 6
    mov ebx, [file_fd]
    int 0x80
    test eax, eax
    js .failed
    xor eax, eax
    ret
.close_failed:
    mov eax, 6
    mov ebx, [file_fd]
    int 0x80
.failed:
    mov eax, -1
    ret

read_history:
    mov eax, 5
    mov ebx, filename
    xor ecx, ecx
    int 0x80
    cmp eax, -2
    je .missing
    test eax, eax
    js .error
    mov [file_fd], eax
.next:
    mov eax, 3
    mov ebx, [file_fd]
    mov ecx, read_buffer
    mov edx, 512
    int 0x80
    cmp eax, -4
    je .next
    test eax, eax
    js .close_error
    jz .close
    mov edx, eax
    mov ecx, read_buffer
    mov ebx, 1
    call write_all
    test eax, eax
    js .close_error
    jmp .next
.close:
    mov eax, 6
    mov ebx, [file_fd]
    int 0x80
    test eax, eax
    js .error
    ret
.close_error:
    mov eax, 6
    mov ebx, [file_fd]
    int 0x80
.error:
    PRINT history_error
    ret
.missing:
    PRINT history_missing
    ret
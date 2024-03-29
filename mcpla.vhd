library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- microcode PLA (NMOS 6502 opcode mask covering)
-- Written by Valerio Venturi
-- output fields format:
-- fields:
-- RSEL:  registers output multiplexer select
-- REGOP: registers load/increment/decrement etc.
-- ALUOP: ALU operation
-- P_OP:  register P set/reset bit
-- MPR:   register MP 
-- PCR:   register PC 
-- CLI:   clear interrupt request
-- BR:    branch opcode
-- EI:    end of microcode sequence
-- W:     read/write control
-- PD:    PC/MP output multiplexer select
entity mcpla is
  port(    a:  in STD_LOGIC_VECTOR(10 downto 0);
           q: out STD_LOGIC_VECTOR(34 downto 0)
      );
end mcpla;

architecture comb of mcpla is

------------------------------------
--            IMPLIED             --
------------------------------------
constant   NOP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11101010000"; -- 0xEA NOP

-- interrupts
constant   BRK_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00000000000"; -- 0x00 BRK/IRQ/NMI/RES
constant   BRK_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00000000001"; -- 0x00 BRK/IRQ/NMI/RES
constant   BRK_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00000000010"; -- 0x00 BRK/IRQ/NMI/RES
constant   BRK_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00000000011"; -- 0x00 BRK/IRQ/NMI/RES
constant   BRK_OP4: STD_LOGIC_VECTOR(10 downto 0) := "00000000100"; -- 0x00 BRK/IRQ/NMI/RES
constant   BRK_OP5: STD_LOGIC_VECTOR(10 downto 0) := "00000000101"; -- 0x00 BRK/IRQ/NMI/RES
constant   BRK_OP6: STD_LOGIC_VECTOR(10 downto 0) := "00000000110"; -- 0x00 BRK/IRQ/NMI/RES

-- IMPLIED
constant   CLC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00011000000"; -- 0x18 CLC 0->C 
constant   SEC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00111000000"; -- 0x38 SEC 1->C
constant   CLI_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01011000000"; -- 0x58 CLI 0->I
constant   SEI_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01111000000"; -- 0x78 SEI 1->I
constant   CLV_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10111000000"; -- 0xB8 CLV 0->V
constant   CLD_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11011000000"; -- 0xD8 CLD 0->D
constant   SED_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11111000000"; -- 0xF8 SED 1->D
constant   TAX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10101010000"; -- 0xAA TAX A->X
constant   TAY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10101000000"; -- 0xA8 TAY A->Y
constant   TXA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10001010000"; -- 0x8A TXA X->A
constant   TYA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10011000000"; -- 0x98 TYA Y->A
constant   TXY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10011011000"; -- 0x9B TXY X->Y
constant   TYX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10111011000"; -- 0xBB TYX Y->X
constant   TXS_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10011010000"; -- 0x9A TXS X->S
constant   TSX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10111010000"; -- 0xBA TSX S->X
constant   TAZ_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00011011000"; -- 0x1B TAZ A->Z
constant   TZA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00111011000"; -- 0x3B TZA Z->A
constant   PHP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00001000000"; -- 0x08 PHP P->S
constant   PHA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01001000000"; -- 0x48 PHA A->S
constant   PHX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11011010000"; -- 0xDA PHX X->S
constant   PHY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01011010000"; -- 0x5A PHY X->S
constant   PHR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10001011000"; -- 0x8B PHR AXY->S
constant   PHR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10001011001"; -- 0x8B PHR AXY->S
constant   PHR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10001011010"; -- 0x8B PHR AXY->S
constant   PLP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00101000000"; -- 0x28 PLP S->P
constant   PLP_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00101000001"; -- 0x28 PLP S->P
constant   PLA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01101000000"; -- 0x68 PLA S->A
constant   PLA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01101000001"; -- 0x68 PLA S->A
constant   PLX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11111010000"; -- 0xFA PLX S->X
constant   PLX_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11111010001"; -- 0xFA PLX S->X
constant   PLY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01111010000"; -- 0x7A PLY S->Y
constant   PLY_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01111010001"; -- 0x7A PLY S->Y
constant   PLR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10101011000"; -- 0xAB PLR S->YXA
constant   PLR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10101011001"; -- 0xAB PLR S->YXA
constant   PLR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10101011010"; -- 0xAB PLR S->YXA
constant   PLR_OP3: STD_LOGIC_VECTOR(10 downto 0) := "10101011011"; -- 0xAB PLR S->YXA
constant   INC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00011010000"; -- 0x1A INC A +1
constant   DEC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00111010000"; -- 0x3A DEC A -1
constant   INX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11101000000"; -- 0xE8 INX X +1
constant   DEX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11001010000"; -- 0xCA DEX X -1
constant   INY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11001000000"; -- 0xC8 INY Y +1
constant   DEY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10001000000"; -- 0x88 DEY Y -1
constant   RTS_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01100000000"; -- 0x60 RTS    
constant   RTS_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01100000001"; -- 0x60 RTS    
constant   RTS_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01100000010"; -- 0x60 RTS    
constant   RTS_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01100000011"; -- 0x60 RTS    
constant   RTS_OP4: STD_LOGIC_VECTOR(10 downto 0) := "01100000100"; -- 0x60 RTS    
constant   RTI_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01000000000"; -- 0x40 RTI    
constant   RTI_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01000000001"; -- 0x40 RTI    
constant   RTI_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01000000010"; -- 0x40 RTI    
constant   RTI_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01000000011"; -- 0x40 RTI    
constant   RTI_OP4: STD_LOGIC_VECTOR(10 downto 0) := "01000000100"; -- 0x40 RTI    
constant   RTI_OP5: STD_LOGIC_VECTOR(10 downto 0) := "01000000101"; -- 0x40 RTI    
constant   ASL_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00001010000"; -- 0x0A ASL A  
constant   LSR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01001010000"; -- 0x4A LSR A  
constant   ROL_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00101010000"; -- 0x2A ROL A  
constant   ROR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01101010000"; -- 0x6A ROR A  
constant   XYX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11101011000"; -- 0xEB EXCHANGE X <-> Y
constant   XYX_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11101011001"; -- 0xEB EXCHANGE X <-> Y
constant   XYX_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11101011010"; -- 0xEB EXCHANGE X <-> Y
constant   XAX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00001011000"; -- 0x0B EXCHANGE A <-> X
constant   XAX_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00001011001"; -- 0x0B EXCHANGE A <-> X
constant   XAX_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00001011010"; -- 0x0B EXCHANGE A <-> X
constant   XAY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00101011000"; -- 0x2B EXCHANGE A <-> Y
constant   XAY_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00101011001"; -- 0x2B EXCHANGE A <-> Y
constant   XAY_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00101011010"; -- 0x2B EXCHANGE A <-> Y
constant   ISP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01001011000"; -- 0x4B init SP X -> S lsb; A -> S msb
constant   ISP_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01001011001"; -- 0x4B init SP X -> S lsb; A -> S msb
constant   TSP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01011011000"; -- 0x5B transfer SP S lsb -> X; S msb -> A 
constant   TSP_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01011011001"; -- 0x5B transfer SP S lsb -> X; S msb -> A

------------------------------------
--           IMMEDIATE            --
------------------------------------
constant IMLDA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10101001000"; -- 0xA9 LDA #IMM
constant IMLDX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10100010000"; -- 0xA2 LDX #IMM
constant IMLDY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10100000000"; -- 0xA0 LDY #IMM
constant IMADC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01101001000"; -- 0x69 ADC #IMM 
constant IMADC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01101001001"; -- 0x69 ADC #IMM 
constant IMSBC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11101001000"; -- 0xE9 SBC #IMM 
constant IMSBC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11101001001"; -- 0xE9 SBC #IMM 
constant IMAND_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00101001000"; -- 0x29 AND #IMM 
constant IMORA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00001001000"; -- 0x09 ORA #IMM 
constant IMEOR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01001001000"; -- 0x49 EOR #IMM 
constant IMCMP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11001001000"; -- 0xC9 CMP #IMM 
constant IMCPX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11100000000"; -- 0xE0 CPX #IMM 
constant IMCPY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11000000000"; -- 0xC0 CPY #IMM 
constant IMBRK_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10001001000"; -- 0x89 BRK #IMM 

------------------------------------
--           ZERO PAGE            --
------------------------------------
constant ZPLDA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10100101000"; -- 0xA5 LDA ZP
constant ZPLDA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10100101001"; -- 0xA5 LDA ZP
constant ZPLDX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10100110000"; -- 0xA6 LDX ZP
constant ZPLDX_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10100110001"; -- 0xA6 LDX ZP
constant ZPLDY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10100100000"; -- 0xA4 LDY ZP
constant ZPLDY_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10100100001"; -- 0xA4 LDY ZP
constant ZPSTA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10000101000"; -- 0x85 STA ZP
constant ZPSTA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10000101001"; -- 0x85 STA ZP
constant ZPSTX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10000110000"; -- 0x86 STX ZP
constant ZPSTX_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10000110001"; -- 0x86 STX ZP
constant ZPSTY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10000100000"; -- 0x84 STY ZP
constant ZPSTY_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10000100001"; -- 0x84 STY ZP
constant ZPSTZ_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01100100000"; -- 0x64 STZ ZP
constant ZPSTZ_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01100100001"; -- 0x64 STZ ZP
constant ZPADC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01100101000"; -- 0x65 ADC ZP
constant ZPADC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01100101001"; -- 0x65 ADC ZP
constant ZPADC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01100101010"; -- 0x65 ADC ZP
constant ZPSBC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11100101000"; -- 0xE5 SBC ZP
constant ZPSBC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11100101001"; -- 0xE5 SBC ZP
constant ZPSBC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11100101010"; -- 0xE5 SBC ZP
constant ZPCMP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11000101000"; -- 0xC5 CMP ZP
constant ZPCMP_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11000101001"; -- 0xC5 CMP ZP
constant ZPCPX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11100100000"; -- 0xE4 CPX ZP
constant ZPCPX_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11100100001"; -- 0xE4 CPX ZP
constant ZPCPY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11000100000"; -- 0xC4 CPY ZP
constant ZPCPY_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11000100001"; -- 0xC4 CPY ZP
constant ZPAND_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00100101000"; -- 0x25 AND ZP
constant ZPAND_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00100101001"; -- 0x25 AND ZP
constant ZPORA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00000101000"; -- 0x05 ORA ZP
constant ZPORA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00000101001"; -- 0x05 ORA ZP
constant ZPEOR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01000101000"; -- 0x45 EOR ZP
constant ZPEOR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01000101001"; -- 0x45 EOR ZP
constant ZPBIT_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00100100000"; -- 0x24 BIT ZP
constant ZPBIT_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00100100001"; -- 0x24 BIT ZP
constant ZPASL_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00000110000"; -- 0x06 ASL ZP 
constant ZPASL_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00000110001"; -- 0x06 ASL ZP 
constant ZPASL_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00000110010"; -- 0x06 ASL ZP 
constant ZPASL_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00000110011"; -- 0x06 ASL ZP 
constant ZPLSR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01000110000"; -- 0x46 LSR ZP 
constant ZPLSR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01000110001"; -- 0x46 LSR ZP 
constant ZPLSR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01000110010"; -- 0x46 LSR ZP 
constant ZPLSR_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01000110011"; -- 0x46 LSR ZP 
constant ZPROL_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00100110000"; -- 0x26 ROL ZP 
constant ZPROL_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00100110001"; -- 0x26 ROL ZP 
constant ZPROL_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00100110010"; -- 0x26 ROL ZP 
constant ZPROL_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00100110011"; -- 0x26 ROL ZP 
constant ZPROR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01100110000"; -- 0x66 ROR ZP 
constant ZPROR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01100110001"; -- 0x66 ROR ZP 
constant ZPROR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01100110010"; -- 0x66 ROR ZP 
constant ZPROR_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01100110011"; -- 0x66 ROR ZP 
constant ZPINC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11100110000"; -- 0xE6 INC ZP 
constant ZPINC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11100110001"; -- 0xE6 INC ZP 
constant ZPINC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11100110010"; -- 0xE6 INC ZP 
constant ZPINC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11100110011"; -- 0xE6 INC ZP 
constant ZPDEC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11000110000"; -- 0xC6 DEC ZP 
constant ZPDEC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11000110001"; -- 0xC6 DEC ZP 
constant ZPDEC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11000110010"; -- 0xC6 DEC ZP 
constant ZPDEC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11000110011"; -- 0xC6 DEC ZP 
constant ZPTSB_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00000100000"; -- 0x04 TSB ZP 
constant ZPTSB_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00000100001"; -- 0x04 TSB ZP 
constant ZPTSB_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00000100010"; -- 0x04 TSB ZP 
constant ZPTSB_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00000100011"; -- 0x04 TSB ZP 
constant ZPTSB_OP4: STD_LOGIC_VECTOR(10 downto 0) := "00000100100"; -- 0x04 TSB ZP 
constant ZPTRB_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00010100000"; -- 0x14 TRB ZP 
constant ZPTRB_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00010100001"; -- 0x14 TRB ZP 
constant ZPTRB_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00010100010"; -- 0x14 TRB ZP 
constant ZPTRB_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00010100011"; -- 0x14 TRB ZP 
constant ZPTRB_OP4: STD_LOGIC_VECTOR(10 downto 0) := "00010100100"; -- 0x14 TRB ZP 

------------------------------------
--          ZERO PAGE,X           --
------------------------------------
constant ZXLDA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10110101000"; -- 0xB5 LDA ZP,X
constant ZXLDA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10110101001"; -- 0xB5 LDA ZP,X
constant ZXLDA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10110101010"; -- 0xB5 LDA ZP,X
constant ZXLDY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10110100000"; -- 0xB4 LDY ZP,X
constant ZXLDY_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10110100001"; -- 0xB4 LDY ZP,X
constant ZXLDY_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10110100010"; -- 0xB4 LDY ZP,X
constant ZXSTA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10010101000"; -- 0x95 STA ZP,X
constant ZXSTA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10010101001"; -- 0x95 STA ZP,X
constant ZXSTA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10010101010"; -- 0x95 STA ZP,X
constant ZXSTY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10010100000"; -- 0x94 STY ZP,X
constant ZXSTY_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10010100001"; -- 0x94 STY ZP,X
constant ZXSTY_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10010100010"; -- 0x94 STY ZP,X
constant ZXSTZ_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01110100000"; -- 0x74 STZ ZP,X
constant ZXSTZ_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01110100001"; -- 0x74 STZ ZP,X
constant ZXSTZ_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01110100010"; -- 0x74 STZ ZP,X
constant ZXADC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01110101000"; -- 0x75 ADC ZP,X
constant ZXADC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01110101001"; -- 0x75 ADC ZP,X
constant ZXADC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01110101010"; -- 0x75 ADC ZP,X
constant ZXADC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01110101011"; -- 0x75 ADC ZP,X
constant ZXSBC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11110101000"; -- 0xF5 SBC ZP,X
constant ZXSBC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11110101001"; -- 0xF5 SBC ZP,X
constant ZXSBC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11110101010"; -- 0xF5 SBC ZP,X
constant ZXSBC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11110101011"; -- 0xF5 SBC ZP,X
constant ZXCMP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11010101000"; -- 0xD5 CMP ZP,X
constant ZXCMP_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11010101001"; -- 0xD5 CMP ZP,X
constant ZXCMP_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11010101010"; -- 0xD5 CMP ZP,X
constant ZXAND_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00110101000"; -- 0x35 AND ZP,X
constant ZXAND_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00110101001"; -- 0x35 AND ZP,X
constant ZXAND_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00110101010"; -- 0x35 AND ZP,X
constant ZXORA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00010101000"; -- 0x15 ORA ZP,X
constant ZXORA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00010101001"; -- 0x15 ORA ZP,X
constant ZXORA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00010101010"; -- 0x15 ORA ZP,X
constant ZXEOR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01010101000"; -- 0x55 EOR ZP,X
constant ZXEOR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01010101001"; -- 0x55 EOR ZP,X
constant ZXEOR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01010101010"; -- 0x55 EOR ZP,X
constant ZXASL_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00010110000"; -- 0x16 ASL ZP,X
constant ZXASL_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00010110001"; -- 0x16 ASL ZP,X
constant ZXASL_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00010110010"; -- 0x16 ASL ZP,X
constant ZXASL_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00010110011"; -- 0x16 ASL ZP,X
constant ZXASL_OP4: STD_LOGIC_VECTOR(10 downto 0) := "00010110100"; -- 0x16 ASL ZP,X
constant ZXLSR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01010110000"; -- 0x56 LSR ZP,X
constant ZXLSR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01010110001"; -- 0x56 LSR ZP,X
constant ZXLSR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01010110010"; -- 0x56 LSR ZP,X
constant ZXLSR_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01010110011"; -- 0x56 LSR ZP,X
constant ZXLSR_OP4: STD_LOGIC_VECTOR(10 downto 0) := "01010110100"; -- 0x56 LSR ZP,X
constant ZXROL_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00110110000"; -- 0x36 ROL ZP,X
constant ZXROL_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00110110001"; -- 0x36 ROL ZP,X
constant ZXROL_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00110110010"; -- 0x36 ROL ZP,X
constant ZXROL_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00110110011"; -- 0x36 ROL ZP,X
constant ZXROL_OP4: STD_LOGIC_VECTOR(10 downto 0) := "00110110100"; -- 0x36 ROL ZP,X
constant ZXROR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01110110000"; -- 0x76 ROR ZP,X
constant ZXROR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01110110001"; -- 0x76 ROR ZP,X
constant ZXROR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01110110010"; -- 0x76 ROR ZP,X
constant ZXROR_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01110110011"; -- 0x76 ROR ZP,X
constant ZXROR_OP4: STD_LOGIC_VECTOR(10 downto 0) := "01110110100"; -- 0x76 ROR ZP,X
constant ZXDEC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11010110000"; -- 0xD6 DEC ZP,X
constant ZXDEC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11010110001"; -- 0xD6 DEC ZP,X
constant ZXDEC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11010110010"; -- 0xD6 DEC ZP,X
constant ZXDEC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11010110011"; -- 0xD6 DEC ZP,X
constant ZXDEC_OP4: STD_LOGIC_VECTOR(10 downto 0) := "11010110100"; -- 0xD6 DEC ZP,X
constant ZXINC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11110110000"; -- 0xF6 INC ZP,X
constant ZXINC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11110110001"; -- 0xF6 INC ZP,X
constant ZXINC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11110110010"; -- 0xF6 INC ZP,X
constant ZXINC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11110110011"; -- 0xF6 INC ZP,X
constant ZXINC_OP4: STD_LOGIC_VECTOR(10 downto 0) := "11110110100"; -- 0xF6 INC ZP,X
constant ZXBIT_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00110100000"; -- 0x34 BIT ZP,X
constant ZXBIT_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00110100001"; -- 0x34 BIT ZP,X
constant ZXBIT_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00110100010"; -- 0x34 BIT ZP,X

------------------------------------
--          ZERO PAGE,Y           --
------------------------------------
constant ZYLDX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10110110000"; -- 0xB6 LDX ZP,Y
constant ZYLDX_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10110110001"; -- 0xB6 LDX ZP,Y
constant ZYLDX_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10110110010"; -- 0xB6 LDX ZP,Y
constant ZYSTX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10010110000"; -- 0x96 STX ZP,Y
constant ZYSTX_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10010110001"; -- 0x96 STX ZP,Y
constant ZYSTX_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10010110010"; -- 0x96 STX ZP,Y

------------------------------------
--           INDIRECT             --
------------------------------------
constant INJMP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01101100000"; -- 0x6C JMP (IND)
constant INJMP_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01101100001"; -- 0x6C JMP (IND)
constant INJMP_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01101100010"; -- 0x6C JMP (IND)
constant INJMP_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01101100011"; -- 0x6C JMP (IND)

------------------------------------
--          INDIRECT,Y            --
------------------------------------
constant IYLDA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10110001000"; -- 0xB1 LDA (IND_ZP),Y
constant IYLDA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10110001001"; -- 0xB1 LDA (IND_ZP),Y
constant IYLDA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10110001010"; -- 0xB1 LDA (IND_ZP),Y
constant IYLDA_OP3: STD_LOGIC_VECTOR(10 downto 0) := "10110001011"; -- 0xB1 LDA (IND_ZP),Y
constant IYLDA_OP4: STD_LOGIC_VECTOR(10 downto 0) := "10110001100"; -- 0xB1 LDA (IND_ZP),Y
constant IYSTA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10010001000"; -- 0x91 STA (IND_ZP),Y
constant IYSTA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10010001001"; -- 0x91 STA (IND_ZP),Y
constant IYSTA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10010001010"; -- 0x91 STA (IND_ZP),Y
constant IYSTA_OP3: STD_LOGIC_VECTOR(10 downto 0) := "10010001011"; -- 0x91 STA (IND_ZP),Y
constant IYSTA_OP4: STD_LOGIC_VECTOR(10 downto 0) := "10010001100"; -- 0x91 STA (IND_ZP),Y
constant IYADC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01110001000"; -- 0x71 ADC (IND_ZP),Y
constant IYADC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01110001001"; -- 0x71 ADC (IND_ZP),Y
constant IYADC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01110001010"; -- 0x71 ADC (IND_ZP),Y
constant IYADC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01110001011"; -- 0x71 ADC (IND_ZP),Y
constant IYADC_OP4: STD_LOGIC_VECTOR(10 downto 0) := "01110001100"; -- 0x71 ADC (IND_ZP),Y
constant IYADC_OP5: STD_LOGIC_VECTOR(10 downto 0) := "01110001101"; -- 0x71 ADC (IND_ZP),Y
constant IYSBC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11110001000"; -- 0xF1 SBC (IND_ZP),Y
constant IYSBC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11110001001"; -- 0xF1 SBC (IND_ZP),Y
constant IYSBC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11110001010"; -- 0xF1 SBC (IND_ZP),Y
constant IYSBC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11110001011"; -- 0xF1 SBC (IND_ZP),Y
constant IYSBC_OP4: STD_LOGIC_VECTOR(10 downto 0) := "11110001100"; -- 0xF1 SBC (IND_ZP),Y
constant IYSBC_OP5: STD_LOGIC_VECTOR(10 downto 0) := "11110001101"; -- 0xF1 SBC (IND_ZP),Y
constant IYCMP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11010001000"; -- 0xD1 CMP (IND_ZP),Y
constant IYCMP_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11010001001"; -- 0xD1 CMP (IND_ZP),Y
constant IYCMP_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11010001010"; -- 0xD1 CMP (IND_ZP),Y
constant IYCMP_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11010001011"; -- 0xD1 CMP (IND_ZP),Y
constant IYCMP_OP4: STD_LOGIC_VECTOR(10 downto 0) := "11010001100"; -- 0xD1 CMP (IND_ZP),Y
constant IYAND_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00110001000"; -- 0x31 AND (IND_ZP),Y
constant IYAND_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00110001001"; -- 0x31 AND (IND_ZP),Y
constant IYAND_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00110001010"; -- 0x31 AND (IND_ZP),Y
constant IYAND_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00110001011"; -- 0x31 AND (IND_ZP),Y
constant IYAND_OP4: STD_LOGIC_VECTOR(10 downto 0) := "00110001100"; -- 0x31 AND (IND_ZP),Y
constant IYORA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00010001000"; -- 0x11 ORA (IND_ZP),Y
constant IYORA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00010001001"; -- 0x11 ORA (IND_ZP),Y
constant IYORA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00010001010"; -- 0x11 ORA (IND_ZP),Y
constant IYORA_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00010001011"; -- 0x11 ORA (IND_ZP),Y
constant IYORA_OP4: STD_LOGIC_VECTOR(10 downto 0) := "00010001100"; -- 0x11 ORA (IND_ZP),Y
constant IYEOR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01010001000"; -- 0x51 EOR (IND_ZP),Y
constant IYEOR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01010001001"; -- 0x51 EOR (IND_ZP),Y
constant IYEOR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01010001010"; -- 0x51 EOR (IND_ZP),Y
constant IYEOR_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01010001011"; -- 0x51 EOR (IND_ZP),Y
constant IYEOR_OP4: STD_LOGIC_VECTOR(10 downto 0) := "01010001100"; -- 0x51 EOR (IND_ZP),Y

------------------------------------
--          INDIRECT,X            --
------------------------------------
constant IXLDA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10100001000"; -- 0xA1 LDA (IND_ZP,X)
constant IXLDA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10100001001"; -- 0xA1 LDA (IND_ZP,X)
constant IXLDA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10100001010"; -- 0xA1 LDA (IND_ZP,X)
constant IXLDA_OP3: STD_LOGIC_VECTOR(10 downto 0) := "10100001011"; -- 0xA1 LDA (IND_ZP,X)
constant IXSTA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10000001000"; -- 0x81 STA (IND_ZP,X)
constant IXSTA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10000001001"; -- 0x81 STA (IND_ZP,X)
constant IXSTA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10000001010"; -- 0x81 STA (IND_ZP,X)
constant IXSTA_OP3: STD_LOGIC_VECTOR(10 downto 0) := "10000001011"; -- 0x81 STA (IND_ZP,X)
constant IXAND_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00100001000"; -- 0x21 AND (IND_ZP,X)
constant IXAND_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00100001001"; -- 0x21 AND (IND_ZP,X)
constant IXAND_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00100001010"; -- 0x21 AND (IND_ZP,X)
constant IXAND_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00100001011"; -- 0x21 AND (IND_ZP,X)
constant IXORA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00000001000"; -- 0x01 ORA (IND_ZP,X)
constant IXORA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00000001001"; -- 0x01 ORA (IND_ZP,X)
constant IXORA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00000001010"; -- 0x01 ORA (IND_ZP,X)
constant IXORA_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00000001011"; -- 0x01 ORA (IND_ZP,X)
constant IXEOR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01000001000"; -- 0x41 EOR (IND_ZP,X)
constant IXEOR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01000001001"; -- 0x41 EOR (IND_ZP,X)
constant IXEOR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01000001010"; -- 0x41 EOR (IND_ZP,X)
constant IXEOR_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01000001011"; -- 0x41 EOR (IND_ZP,X)
constant IXCMP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11000001000"; -- 0xC1 CMP (IND_ZP,X)
constant IXCMP_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11000001001"; -- 0xC1 CMP (IND_ZP,X)
constant IXCMP_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11000001010"; -- 0xC1 CMP (IND_ZP,X)
constant IXCMP_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11000001011"; -- 0xC1 CMP (IND_ZP,X)
constant IXADC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01100001000"; -- 0x61 ADC (IND_ZP,X)
constant IXADC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01100001001"; -- 0x61 ADC (IND_ZP,X)
constant IXADC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01100001010"; -- 0x61 ADC (IND_ZP,X)
constant IXADC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01100001011"; -- 0x61 ADC (IND_ZP,X)
constant IXADC_OP4: STD_LOGIC_VECTOR(10 downto 0) := "01100001100"; -- 0x61 ADC (IND_ZP,X)
constant IXSBC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11100001000"; -- 0xE1 SBC (IND_ZP,X)
constant IXSBC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11100001001"; -- 0xE1 SBC (IND_ZP,X)
constant IXSBC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11100001010"; -- 0xE1 SBC (IND_ZP,X)
constant IXSBC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11100001011"; -- 0xE1 SBC (IND_ZP,X)
constant IXSBC_OP4: STD_LOGIC_VECTOR(10 downto 0) := "11100001100"; -- 0xE1 SBC (IND_ZP,X)
constant IXJMP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01111100000"; -- 0x7C JMP (IND,X)
constant IXJMP_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01111100001"; -- 0x7C JMP (IND,X)
constant IXJMP_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01111100010"; -- 0x7C JMP (IND,X)
constant IXJMP_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01111100011"; -- 0x7C JMP (IND,X)
constant IXJMP_OP4: STD_LOGIC_VECTOR(10 downto 0) := "01111100100"; -- 0x7C JMP (IND,X)
constant IXJSR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11111100000"; -- 0xFC JSR (IND,X)
constant IXJSR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11111100001"; -- 0xFC JSR (IND,X)
constant IXJSR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11111100010"; -- 0xFC JSR (IND,X)
constant IXJSR_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11111100011"; -- 0xFC JSR (IND,X)
constant IXJSR_OP4: STD_LOGIC_VECTOR(10 downto 0) := "11111100100"; -- 0xFC JSR (IND,X)
constant IXJSR_OP5: STD_LOGIC_VECTOR(10 downto 0) := "11111100101"; -- 0xFC JSR (IND,X)

------------------------------------
--            ABSOLUTE            --
------------------------------------
constant ABLDA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10101101000"; -- 0xAD LDA ABS
constant ABLDA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10101101001"; -- 0xAD LDA ABS
constant ABLDA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10101101010"; -- 0xAD LDA ABS
constant ABLDX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10101110000"; -- 0xAE LDX ABS
constant ABLDX_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10101110001"; -- 0xAE LDX ABS
constant ABLDX_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10101110010"; -- 0xAE LDX ABS
constant ABLDY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10101100000"; -- 0xAC LDY ABS
constant ABLDY_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10101100001"; -- 0xAC LDY ABS
constant ABLDY_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10101100010"; -- 0xAC LDY ABS
constant ABSTA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10001101000"; -- 0x8D STA ABS
constant ABSTA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10001101001"; -- 0x8D STA ABS
constant ABSTA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10001101010"; -- 0x8D STA ABS
constant ABSTX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10001110000"; -- 0x8E STX ABS
constant ABSTX_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10001110001"; -- 0x8E STX ABS
constant ABSTX_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10001110010"; -- 0x8E STX ABS
constant ABSTY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10001100000"; -- 0x8C STY ABS
constant ABSTY_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10001100001"; -- 0x8C STY ABS
constant ABSTY_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10001100010"; -- 0x8C STY ABS
constant ABSTZ_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10011100000"; -- 0x9C STZ ABS
constant ABSTZ_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10011100001"; -- 0x9C STZ ABS
constant ABSTZ_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10011100010"; -- 0x9C STZ ABS
constant ABADC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01101101000"; -- 0x6D ADC ABS
constant ABADC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01101101001"; -- 0x6D ADC ABS
constant ABADC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01101101010"; -- 0x6D ADC ABS
constant ABADC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01101101011"; -- 0x6D ADC ABS
constant ABSBC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11101101000"; -- 0xED SBC ABS
constant ABSBC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11101101001"; -- 0xED SBC ABS
constant ABSBC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11101101010"; -- 0xED SBC ABS
constant ABSBC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11101101011"; -- 0xED SBC ABS
constant ABORA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00001101000"; -- 0x0D ORA ABS
constant ABORA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00001101001"; -- 0x0D ORA ABS
constant ABORA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00001101010"; -- 0x0D ORA ABS
constant ABAND_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00101101000"; -- 0x2D AND ABS
constant ABAND_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00101101001"; -- 0x2D AND ABS
constant ABAND_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00101101010"; -- 0x2D AND ABS
constant ABEOR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01001101000"; -- 0x4D EOR ABS
constant ABEOR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01001101001"; -- 0x4D EOR ABS
constant ABEOR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01001101010"; -- 0x4D EOR ABS
constant ABCMP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11001101000"; -- 0xCD CMP ABS
constant ABCMP_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11001101001"; -- 0xCD CMP ABS
constant ABCMP_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11001101010"; -- 0xCD CMP ABS
constant ABCPX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11101100000"; -- 0xEC CPX ABS
constant ABCPX_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11101100001"; -- 0xEC CPX ABS
constant ABCPX_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11101100010"; -- 0xEC CPX ABS
constant ABCPY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11001100000"; -- 0xCC CPY ABS
constant ABCPY_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11001100001"; -- 0xCC CPY ABS
constant ABCPY_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11001100010"; -- 0xCC CPY ABS
constant ABJMP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01001100000"; -- 0x4C JMP ABS
constant ABJMP_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01001100001"; -- 0x4C JMP ABS
constant ABJSR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00100000000"; -- 0x20 JSR ABS
constant ABJSR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00100000001"; -- 0x20 JSR ABS
constant ABJSR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00100000010"; -- 0x20 JSR ABS
constant ABJSR_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00100000011"; -- 0x20 JSR ABS
constant ABBIT_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00101100000"; -- 0x2C BIT ABS
constant ABBIT_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00101100001"; -- 0x2C BIT ABS
constant ABBIT_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00101100010"; -- 0x2C BIT ABS
constant ABASL_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00001110000"; -- 0x0E ASL ABS
constant ABASL_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00001110001"; -- 0x0E ASL ABS
constant ABASL_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00001110010"; -- 0x0E ASL ABS
constant ABASL_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00001110011"; -- 0x0E ASL ABS
constant ABASL_OP4: STD_LOGIC_VECTOR(10 downto 0) := "00001110100"; -- 0x0E ASL ABS
constant ABLSR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01001110000"; -- 0x4E LSR ABS
constant ABLSR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01001110001"; -- 0x4E LSR ABS
constant ABLSR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01001110010"; -- 0x4E LSR ABS
constant ABLSR_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01001110011"; -- 0x4E LSR ABS
constant ABLSR_OP4: STD_LOGIC_VECTOR(10 downto 0) := "01001110100"; -- 0x4E LSR ABS
constant ABROL_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00101110000"; -- 0x2E ROL ABS
constant ABROL_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00101110001"; -- 0x2E ROL ABS
constant ABROL_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00101110010"; -- 0x2E ROL ABS
constant ABROL_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00101110011"; -- 0x2E ROL ABS
constant ABROL_OP4: STD_LOGIC_VECTOR(10 downto 0) := "00101110100"; -- 0x2E ROL ABS
constant ABROR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01101110000"; -- 0x6E ROR ABS
constant ABROR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01101110001"; -- 0x6E ROR ABS
constant ABROR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01101110010"; -- 0x6E ROR ABS
constant ABROR_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01101110011"; -- 0x6E ROR ABS
constant ABROR_OP4: STD_LOGIC_VECTOR(10 downto 0) := "01101110100"; -- 0x6E ROR ABS
constant ABINC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11101110000"; -- 0xEE INC ABS
constant ABINC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11101110001"; -- 0xEE INC ABS
constant ABINC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11101110010"; -- 0xEE INC ABS
constant ABINC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11101110011"; -- 0xEE INC ABS
constant ABINC_OP4: STD_LOGIC_VECTOR(10 downto 0) := "11101110100"; -- 0xEE INC ABS
constant ABDEC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11001110000"; -- 0xCE DEC ABS
constant ABDEC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11001110001"; -- 0xCE DEC ABS
constant ABDEC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11001110010"; -- 0xCE DEC ABS
constant ABDEC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11001110011"; -- 0xCE DEC ABS
constant ABDEC_OP4: STD_LOGIC_VECTOR(10 downto 0) := "11001110100"; -- 0xCE DEC ABS
constant ABTSB_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00001100000"; -- 0x0C TSB ABS
constant ABTSB_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00001100001"; -- 0x0C TSB ABS
constant ABTSB_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00001100010"; -- 0x0C TSB ABS
constant ABTSB_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00001100011"; -- 0x0C TSB ABS
constant ABTSB_OP4: STD_LOGIC_VECTOR(10 downto 0) := "00001100100"; -- 0x0C TSB ABS
constant ABTSB_OP5: STD_LOGIC_VECTOR(10 downto 0) := "00001100101"; -- 0x0C TSB ABS
constant ABTRB_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00011100000"; -- 0x1C TRB ABS
constant ABTRB_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00011100001"; -- 0x1C TRB ABS
constant ABTRB_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00011100010"; -- 0x1C TRB ABS
constant ABTRB_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00011100011"; -- 0x1C TRB ABS
constant ABTRB_OP4: STD_LOGIC_VECTOR(10 downto 0) := "00011100100"; -- 0x1C TRB ABS
constant ABTRB_OP5: STD_LOGIC_VECTOR(10 downto 0) := "00011100101"; -- 0x1C TRB ABS

------------------------------------
--           ABSOLUTE,X           --
------------------------------------
constant AXLDA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10111101000"; -- 0xBD LDA ABS,X
constant AXLDA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10111101001"; -- 0xBD LDA ABS,X
constant AXLDA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10111101010"; -- 0xBD LDA ABS,X
constant AXLDA_OP3: STD_LOGIC_VECTOR(10 downto 0) := "10111101011"; -- 0xBD LDA ABS,X
constant AXLDY_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10111100000"; -- 0xBC LDY ABS,X
constant AXLDY_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10111100001"; -- 0xBC LDY ABS,X
constant AXLDY_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10111100010"; -- 0xBC LDY ABS,X
constant AXLDY_OP3: STD_LOGIC_VECTOR(10 downto 0) := "10111100011"; -- 0xBC LDY ABS,X
constant AXSTA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10011101000"; -- 0x9D STA ABS,X
constant AXSTA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10011101001"; -- 0x9D STA ABS,X
constant AXSTA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10011101010"; -- 0x9D STA ABS,X
constant AXSTA_OP3: STD_LOGIC_VECTOR(10 downto 0) := "10011101011"; -- 0x9D STA ABS,X
constant AXSTZ_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10011110000"; -- 0x9E STZ ABS,X
constant AXSTZ_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10011110001"; -- 0x9E STZ ABS,X
constant AXSTZ_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10011110010"; -- 0x9E STZ ABS,X
constant AXSTZ_OP3: STD_LOGIC_VECTOR(10 downto 0) := "10011110011"; -- 0x9E STZ ABS,X
constant AXADC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01111101000"; -- 0x7D ADC ABS,X
constant AXADC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01111101001"; -- 0x7D ADC ABS,X
constant AXADC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01111101010"; -- 0x7D ADC ABS,X
constant AXADC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01111101011"; -- 0x7D ADC ABS,X
constant AXADC_OP4: STD_LOGIC_VECTOR(10 downto 0) := "01111101100"; -- 0x7D ADC ABS,X
constant AXSBC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11111101000"; -- 0xFD SBC ABS,X
constant AXSBC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11111101001"; -- 0xFD SBC ABS,X
constant AXSBC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11111101010"; -- 0xFD SBC ABS,X
constant AXSBC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11111101011"; -- 0xFD SBC ABS,X
constant AXSBC_OP4: STD_LOGIC_VECTOR(10 downto 0) := "11111101100"; -- 0xFD SBC ABS,X
constant AXCMP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11011101000"; -- 0xDD CMP ABS,X
constant AXCMP_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11011101001"; -- 0xDD CMP ABS,X
constant AXCMP_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11011101010"; -- 0xDD CMP ABS,X
constant AXCMP_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11011101011"; -- 0xDD CMP ABS,X
constant AXINC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11111110000"; -- 0xFE INC ABS,X
constant AXINC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11111110001"; -- 0xFE INC ABS,X
constant AXINC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11111110010"; -- 0xFE INC ABS,X
constant AXINC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11111110011"; -- 0xFE INC ABS,X
constant AXINC_OP4: STD_LOGIC_VECTOR(10 downto 0) := "11111110100"; -- 0xFE INC ABS,X
constant AXINC_OP5: STD_LOGIC_VECTOR(10 downto 0) := "11111110101"; -- 0xFE INC ABS,X
constant AXDEC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11011110000"; -- 0xDE DEC ABS,X
constant AXDEC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11011110001"; -- 0xDE DEC ABS,X
constant AXDEC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11011110010"; -- 0xDE DEC ABS,X
constant AXDEC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11011110011"; -- 0xDE DEC ABS,X
constant AXDEC_OP4: STD_LOGIC_VECTOR(10 downto 0) := "11011110100"; -- 0xDE DEC ABS,X
constant AXDEC_OP5: STD_LOGIC_VECTOR(10 downto 0) := "11011110101"; -- 0xDE DEC ABS,X
constant AXASL_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00011110000"; -- 0x1E ASL ABS,X
constant AXASL_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00011110001"; -- 0x1E ASL ABS,X
constant AXASL_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00011110010"; -- 0x1E ASL ABS,X
constant AXASL_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00011110011"; -- 0x1E ASL ABS,X
constant AXASL_OP4: STD_LOGIC_VECTOR(10 downto 0) := "00011110100"; -- 0x1E ASL ABS,X
constant AXASL_OP5: STD_LOGIC_VECTOR(10 downto 0) := "00011110101"; -- 0x1E ASL ABS,X
constant AXLSR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01011110000"; -- 0x5E LSR ABS,X
constant AXLSR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01011110001"; -- 0x5E LSR ABS,X
constant AXLSR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01011110010"; -- 0x5E LSR ABS,X
constant AXLSR_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01011110011"; -- 0x5E LSR ABS,X
constant AXLSR_OP4: STD_LOGIC_VECTOR(10 downto 0) := "01011110100"; -- 0x5E LSR ABS,X
constant AXLSR_OP5: STD_LOGIC_VECTOR(10 downto 0) := "01011110101"; -- 0x5E LSR ABS,X
constant AXROL_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00111110000"; -- 0x3E ROL ABS,X
constant AXROL_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00111110001"; -- 0x3E ROL ABS,X
constant AXROL_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00111110010"; -- 0x3E ROL ABS,X
constant AXROL_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00111110011"; -- 0x3E ROL ABS,X
constant AXROL_OP4: STD_LOGIC_VECTOR(10 downto 0) := "00111110100"; -- 0x3E ROL ABS,X
constant AXROL_OP5: STD_LOGIC_VECTOR(10 downto 0) := "00111110101"; -- 0x3E ROL ABS,X
constant AXROR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01111110000"; -- 0x7E ROR ABS,X
constant AXROR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01111110001"; -- 0x7E ROR ABS,X
constant AXROR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01111110010"; -- 0x7E ROR ABS,X
constant AXROR_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01111110011"; -- 0x7E ROR ABS,X
constant AXROR_OP4: STD_LOGIC_VECTOR(10 downto 0) := "01111110100"; -- 0x7E ROR ABS,X
constant AXROR_OP5: STD_LOGIC_VECTOR(10 downto 0) := "01111110101"; -- 0x7E ROR ABS,X
constant AXAND_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00111101000"; -- 0x3D AND ABS,X
constant AXAND_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00111101001"; -- 0x3D AND ABS,X
constant AXAND_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00111101010"; -- 0x3D AND ABS,X
constant AXAND_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00111101011"; -- 0x3D AND ABS,X
constant AXORA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00011101000"; -- 0x1D ORA ABS,X
constant AXORA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00011101001"; -- 0x1D ORA ABS,X
constant AXORA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00011101010"; -- 0x1D ORA ABS,X
constant AXORA_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00011101011"; -- 0x1D ORA ABS,X
constant AXEOR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01011101000"; -- 0x5D EOR ABS,X
constant AXEOR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01011101001"; -- 0x5D EOR ABS,X
constant AXEOR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01011101010"; -- 0x5D EOR ABS,X
constant AXEOR_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01011101011"; -- 0x5D EOR ABS,X
constant AXBIT_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00111100000"; -- 0x3C BIT ABS,X
constant AXBIT_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00111100001"; -- 0x3C BIT ABS,X
constant AXBIT_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00111100010"; -- 0x3C BIT ABS,X
constant AXBIT_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00111100011"; -- 0x3C BIT ABS,X

------------------------------------
--           ABSOLUTE,Y           --
------------------------------------
constant AYLDA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10111001000"; -- 0xB9 LDA ABS,Y
constant AYLDA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10111001001"; -- 0xB9 LDA ABS,Y
constant AYLDA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10111001010"; -- 0xB9 LDA ABS,Y
constant AYLDA_OP3: STD_LOGIC_VECTOR(10 downto 0) := "10111001011"; -- 0xB9 LDA ABS,Y
constant AYLDX_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10111110000"; -- 0xBE LDX ABS,Y
constant AYLDX_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10111110001"; -- 0xBE LDX ABS,Y
constant AYLDX_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10111110010"; -- 0xBE LDX ABS,Y
constant AYLDX_OP3: STD_LOGIC_VECTOR(10 downto 0) := "10111110011"; -- 0xBE LDX ABS,Y
constant AYSTA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10011001000"; -- 0x99 STA ABS,Y
constant AYSTA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10011001001"; -- 0x99 STA ABS,Y
constant AYSTA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10011001010"; -- 0x99 STA ABS,Y
constant AYSTA_OP3: STD_LOGIC_VECTOR(10 downto 0) := "10011001011"; -- 0x99 STA ABS,Y
constant AYADC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01111001000"; -- 0x79 ADC ABS,Y
constant AYADC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01111001001"; -- 0x79 ADC ABS,Y
constant AYADC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01111001010"; -- 0x79 ADC ABS,Y
constant AYADC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01111001011"; -- 0x79 ADC ABS,Y
constant AYADC_OP4: STD_LOGIC_VECTOR(10 downto 0) := "01111001100"; -- 0x79 ADC ABS,Y
constant AYSBC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11111001000"; -- 0xF9 SBC ABS,Y
constant AYSBC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11111001001"; -- 0xF9 SBC ABS,Y
constant AYSBC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11111001010"; -- 0xF9 SBC ABS,Y
constant AYSBC_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11111001011"; -- 0xF9 SBC ABS,Y
constant AYSBC_OP4: STD_LOGIC_VECTOR(10 downto 0) := "11111001100"; -- 0xF9 SBC ABS,Y
constant AYCMP_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11011001000"; -- 0xD9 CMP ABS,Y
constant AYCMP_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11011001001"; -- 0xD9 CMP ABS,Y
constant AYCMP_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11011001010"; -- 0xD9 CMP ABS,Y
constant AYCMP_OP3: STD_LOGIC_VECTOR(10 downto 0) := "11011001011"; -- 0xD9 CMP ABS,Y
constant AYORA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00011001000"; -- 0x19 ORA ABS,Y
constant AYORA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00011001001"; -- 0x19 ORA ABS,Y
constant AYORA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00011001010"; -- 0x19 ORA ABS,Y
constant AYORA_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00011001011"; -- 0x19 ORA ABS,Y
constant AYAND_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00111001000"; -- 0x39 AND ABS,Y
constant AYAND_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00111001001"; -- 0x39 AND ABS,Y
constant AYAND_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00111001010"; -- 0x39 AND ABS,Y
constant AYAND_OP3: STD_LOGIC_VECTOR(10 downto 0) := "00111001011"; -- 0x39 AND ABS,Y
constant AYEOR_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01011001000"; -- 0x59 EOR ABS,Y
constant AYEOR_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01011001001"; -- 0x59 EOR ABS,Y
constant AYEOR_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01011001010"; -- 0x59 EOR ABS,Y
constant AYEOR_OP3: STD_LOGIC_VECTOR(10 downto 0) := "01011001011"; -- 0x59 EOR ABS,Y

------------------------------------
--           RELATIVE             --
------------------------------------
constant BRA_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10000000000"; -- 0x80 BRA       
constant BRA_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10000000001"; -- 0x80 BRA       
constant BRA_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10000000010"; -- 0x80 BRA       
constant BCC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10010000000"; -- 0x90 BCC       
constant BCC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10010000001"; -- 0x90 BCC       
constant BCC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10010000010"; -- 0x90 BCC       
constant BCS_OP0: STD_LOGIC_VECTOR(10 downto 0) := "10110000000"; -- 0xB0 BCS       
constant BCS_OP1: STD_LOGIC_VECTOR(10 downto 0) := "10110000001"; -- 0xB0 BCS       
constant BCS_OP2: STD_LOGIC_VECTOR(10 downto 0) := "10110000010"; -- 0xB0 BCS       
constant BEQ_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11110000000"; -- 0xF0 BEQ       
constant BEQ_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11110000001"; -- 0xF0 BEQ       
constant BEQ_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11110000010"; -- 0xF0 BEQ       
constant BNE_OP0: STD_LOGIC_VECTOR(10 downto 0) := "11010000000"; -- 0xD0 BNE       
constant BNE_OP1: STD_LOGIC_VECTOR(10 downto 0) := "11010000001"; -- 0xD0 BNE       
constant BNE_OP2: STD_LOGIC_VECTOR(10 downto 0) := "11010000010"; -- 0xD0 BNE       
constant BPL_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00010000000"; -- 0x10 BPL       
constant BPL_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00010000001"; -- 0x10 BPL       
constant BPL_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00010000010"; -- 0x10 BPL       
constant BMI_OP0: STD_LOGIC_VECTOR(10 downto 0) := "00110000000"; -- 0x30 BMI       
constant BMI_OP1: STD_LOGIC_VECTOR(10 downto 0) := "00110000001"; -- 0x30 BMI       
constant BMI_OP2: STD_LOGIC_VECTOR(10 downto 0) := "00110000010"; -- 0x30 BMI       
constant BVC_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01010000000"; -- 0x50 BVC       
constant BVC_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01010000001"; -- 0x50 BVC       
constant BVC_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01010000010"; -- 0x50 BVC       
constant BVS_OP0: STD_LOGIC_VECTOR(10 downto 0) := "01110000000"; -- 0x70 BVS       
constant BVS_OP1: STD_LOGIC_VECTOR(10 downto 0) := "01110000001"; -- 0x70 BVS       
constant BVS_OP2: STD_LOGIC_VECTOR(10 downto 0) := "01110000010"; -- 0x70 BVS       
 
-- ALU microcode
constant NOP_A: STD_LOGIC_VECTOR(4 downto 0) := "00000"; -- ALU no operation
constant SUM_A: STD_LOGIC_VECTOR(4 downto 0) := "00001"; -- ALU add with carry
constant SUB_A: STD_LOGIC_VECTOR(4 downto 0) := "00010"; -- ALU sub with borrow
constant AND_A: STD_LOGIC_VECTOR(4 downto 0) := "00011"; -- ALU and
constant  OR_A: STD_LOGIC_VECTOR(4 downto 0) := "00100"; -- ALU or
constant XOR_A: STD_LOGIC_VECTOR(4 downto 0) := "00101"; -- ALU xor
constant INC_A: STD_LOGIC_VECTOR(4 downto 0) := "00110"; -- ALU increment by 1
constant DEC_A: STD_LOGIC_VECTOR(4 downto 0) := "00111"; -- ALU decrement by 1
constant SHL_A: STD_LOGIC_VECTOR(4 downto 0) := "01000"; -- ALU bit shift left
constant SHR_A: STD_LOGIC_VECTOR(4 downto 0) := "01001"; -- ALU bit shift right
constant ROL_A: STD_LOGIC_VECTOR(4 downto 0) := "01010"; -- ALU bit rotation left
constant ROR_A: STD_LOGIC_VECTOR(4 downto 0) := "01011"; -- ALU bit rotation right
constant SWC_A: STD_LOGIC_VECTOR(4 downto 0) := "01100"; -- ALU add without carry
constant BIT_A: STD_LOGIC_VECTOR(4 downto 0) := "01101"; -- ALU bit test
constant DAA_A: STD_LOGIC_VECTOR(4 downto 0) := "01110"; -- ALU add without carry (used for DAA decimal adjustement)
constant DAS_A: STD_LOGIC_VECTOR(4 downto 0) := "01111"; -- ALU sub without borrow (used for DAA decimal adjustement)
constant CMP_A: STD_LOGIC_VECTOR(4 downto 0) := "10000"; -- SBC without borrow in (used for CMP instruction)
constant TSB_A: STD_LOGIC_VECTOR(4 downto 0) := "10001"; -- test and set bit
constant TRB_A: STD_LOGIC_VECTOR(4 downto 0) := "10010"; -- test and reset bit

-- PCR microcode
constant NOP_PC: STD_LOGIC_VECTOR(2 downto 0) := "000"; -- PC no operation
constant LSB_PC: STD_LOGIC_VECTOR(2 downto 0) := "001"; -- PC load lsb
constant MSB_PC: STD_LOGIC_VECTOR(2 downto 0) := "010"; -- PC load msb
constant INC_PC: STD_LOGIC_VECTOR(2 downto 0) := "011"; -- PC increment by 1
constant LOD_PC: STD_LOGIC_VECTOR(2 downto 0) := "100"; -- PC load lsb\msb
constant ADJ_PC: STD_LOGIC_VECTOR(2 downto 0) := "101"; -- PC msb adjustement (+/- by 1)

-- MPR microcode
constant NOP_M: STD_LOGIC_VECTOR(3 downto 0) := "0000"; -- no operation
constant LSB_M: STD_LOGIC_VECTOR(3 downto 0) := "0001"; -- load lsb
constant MSB_M: STD_LOGIC_VECTOR(3 downto 0) := "0010"; -- load msb
constant INC_M: STD_LOGIC_VECTOR(3 downto 0) := "0011"; -- increment LSB
constant VEC_M: STD_LOGIC_VECTOR(3 downto 0) := "0100"; -- load vector
constant ZPL_M: STD_LOGIC_VECTOR(3 downto 0) := "0101"; -- load ZEROPAGE
constant ALL_M: STD_LOGIC_VECTOR(3 downto 0) := "0110"; -- load all 16 bit register
constant ICC_M: STD_LOGIC_VECTOR(3 downto 0) := "0111"; -- increment MSB with carry
constant INM_M: STD_LOGIC_VECTOR(3 downto 0) := "1000"; -- increment MSB/LSB

-- address multiplexer microcode
constant ADPC: STD_LOGIC_VECTOR(1 downto 0) := "00";    -- select PC
constant ADMP: STD_LOGIC_VECTOR(1 downto 0) := "01";    -- select MP
constant ADSP: STD_LOGIC_VECTOR(1 downto 0) := "10";    -- select MP/SP
constant ADNP: STD_LOGIC_VECTOR(1 downto 0) := "00";    -- no operation

-- PR microcode
constant NOP_P: STD_LOGIC_VECTOR(3 downto 0) := "0000"; -- PR no operation
constant PLD_P: STD_LOGIC_VECTOR(3 downto 0) := "0001"; -- PR load
constant FLD_P: STD_LOGIC_VECTOR(3 downto 0) := "0010"; -- NZ load
constant FLC_P: STD_LOGIC_VECTOR(3 downto 0) := "0011"; -- NZC load
constant FLV_P: STD_LOGIC_VECTOR(3 downto 0) := "0100"; -- NVZC load
constant SEC_P: STD_LOGIC_VECTOR(3 downto 0) := "0101"; -- 1 => C 
constant CLC_P: STD_LOGIC_VECTOR(3 downto 0) := "0110"; -- 0 => C 
constant SEI_P: STD_LOGIC_VECTOR(3 downto 0) := "0111"; -- 1 => I 
constant CLI_P: STD_LOGIC_VECTOR(3 downto 0) := "1000"; -- 0 => I 
constant SED_P: STD_LOGIC_VECTOR(3 downto 0) := "1001"; -- 1 => D 
constant CLD_P: STD_LOGIC_VECTOR(3 downto 0) := "1010"; -- 0 => D 
constant CLV_P: STD_LOGIC_VECTOR(3 downto 0) := "1011"; -- 0 => V 
constant AUC_P: STD_LOGIC_VECTOR(3 downto 0) := "1100"; -- auc => ACR 
constant HAC_P: STD_LOGIC_VECTOR(3 downto 0) := "1101"; -- hold ACR 
constant SID_P: STD_LOGIC_VECTOR(3 downto 0) := "1110"; -- 1 => I/D 
constant LDZ_P: STD_LOGIC_VECTOR(3 downto 0) := "1111"; -- Z load

-- register operation microcode REGOP
constant NOP_R: STD_LOGIC_VECTOR(3 downto 0) := "0000";  -- no operation
constant ALD_R: STD_LOGIC_VECTOR(3 downto 0) := "0001";  -- register A load
constant XLD_R: STD_LOGIC_VECTOR(3 downto 0) := "0010";  -- register X load
constant YLD_R: STD_LOGIC_VECTOR(3 downto 0) := "0011";  -- register Y load
constant ZLD_R: STD_LOGIC_VECTOR(3 downto 0) := "0100";  -- register Z load
constant OLD_R: STD_LOGIC_VECTOR(3 downto 0) := "0101";  -- register O load
constant SLD_R: STD_LOGIC_VECTOR(3 downto 0) := "0110";  -- register S load lsb
constant SLM_R: STD_LOGIC_VECTOR(3 downto 0) := "0111";  -- register S load msb
constant SUP_R: STD_LOGIC_VECTOR(3 downto 0) := "1000";  -- register S increment by 1
constant SDW_R: STD_LOGIC_VECTOR(3 downto 0) := "1001";  -- register S decrement by 1
constant SAU_R: STD_LOGIC_VECTOR(3 downto 0) := "1010";  -- register A load/register S increment by 1
constant SXU_R: STD_LOGIC_VECTOR(3 downto 0) := "1011";  -- register X load/register S increment by 1
constant SYU_R: STD_LOGIC_VECTOR(3 downto 0) := "1100";  -- register Y load/register S increment by 1
constant SZU_R: STD_LOGIC_VECTOR(3 downto 0) := "1101";  -- register Z load/register S increment by 1

-- register multiplexer microcode RSEL (ALU operand #1)
constant EXT_O: STD_LOGIC_VECTOR(3 downto 0) := "0000";  -- external data bus
constant ARD_O: STD_LOGIC_VECTOR(3 downto 0) := "0001";  -- register A select
constant XRD_O: STD_LOGIC_VECTOR(3 downto 0) := "0010";  -- register X select
constant YRD_O: STD_LOGIC_VECTOR(3 downto 0) := "0011";  -- register Y select
constant SRD_O: STD_LOGIC_VECTOR(3 downto 0) := "0100";  -- register S lsb select
constant SRM_O: STD_LOGIC_VECTOR(3 downto 0) := "0101";  -- register S msb select
constant PRD_O: STD_LOGIC_VECTOR(3 downto 0) := "0110";  -- register P select
constant PLR_O: STD_LOGIC_VECTOR(3 downto 0) := "0111";  -- register PCL select
constant PHR_O: STD_LOGIC_VECTOR(3 downto 0) := "1000";  -- register PCH select
constant ORD_O: STD_LOGIC_VECTOR(3 downto 0) := "1001";  -- register O select
constant Z00_O: STD_LOGIC_VECTOR(3 downto 0) := "1010";  -- select (all zero output)
constant ZRD_O: STD_LOGIC_VECTOR(3 downto 0) := "1011";  -- register Z select (all zero output)

-- data multiplexer microcode DMUX (ALU operand #2)
constant NOP_D: STD_LOGIC_VECTOR(1 downto 0) := "00";
constant ORD_D: STD_LOGIC_VECTOR(1 downto 0) := "01";
constant EXT_D: STD_LOGIC_VECTOR(1 downto 0) := "10";
constant BCD_D: STD_LOGIC_VECTOR(1 downto 0) := "11";

-- read/write control
constant   RDE: STD_LOGIC_VECTOR(1 downto 0) := "11";    -- data bus read
constant   WRE: STD_LOGIC_VECTOR(1 downto 0) := "10";    -- data bus write (combinatorial mode)
constant   WRL: STD_LOGIC_VECTOR(1 downto 0) := "01";    -- data bus write (registered mode)

begin
  process(a)
  begin                    
  -- The PLA is arranged like an ROM, there are an address input "a" and an data output "q". The address of PLA is 11 bit wide 
  -- and composed in this way:
  --
  -- ----  CPU OPCODE   ----  - MPC -
  -- |                     |  |     |  
  -- |                     |  |     |  
  --  X--X--X--X--X--X--X--X--Y--Y--Y 
  -- 10-09-08-07-06-05-04-03-02-01-00
  --
  -- the bits (10-3) (X field) is formed by CPU instruction opcode 
  -- the bits (2-0) (Y field) is formed by the three bit wide microinstruction program counter (MPC)  
  -- The MPC field is cleared at each opcode fetch by FSM and since it's three bit wide there are
  -- an maximum of eight microinstructions available per opcode 
  --
  -- The bits 10-3 of PLA address serves to select the microcode group of a related CPU opcode 
  -- and they are stable for all instruction execution time, instead the remaining three bit 2-0 (MPC field) of PLA address 
  -- increment at each clock in order to address the next microcode instructions.   
  -- microcode assembly:
  -- Due the particulary pipeline structure of this CPU, all microinstructions have an extra cycle hidden on fetch 
  -- of the next opcode instruction and normally this extra cycle is coded as "NOP" (see the last line  "when  others =>...").
  -- However there are some instructions where this extra cycle is used for some functions like decimal adjustments etc of
  -- ADC and SBC instructions (see DAA and DAS).
  --
  -- Microcode fields:
  --     
  --                          DMUX: ALU operand #2 multiplexer
  --                          |       AI: effective address is indexed (X or Y)
  --                          |       |   VP: vector pull
  --                          |       |   |   BR: branch opcode
  --                          |       |   |   |   EI: end of microcode sequence (the hidden extra cycle it's always executed after this microinstruction) 
  --                          |       |   |   |   |   W: read/write control
  --                          |       |   |   |   |   |    CLI: clear interrupt request
  --                          |       |   |   |   |   |    |    PD: PC/MP address output multiplexer select
  --                          |       |   |   |   |   |    |    |      PCR: register PC (program counter)
  --                          |       |   |   |   |   |    |    |      |        MPR: register MP (memory pointer)
  --                          |       |   |   |   |   |    |    |      |        |       P_OP: register P set/reset bit
  --                          |       |   |   |   |   |    |    |      |        |       |       ALUOP: ALU operation
  --                          |       |   |   |   |   |    |    |      |        |       |       |       REGOP: registers load/increment/decrement etc.
  --                          |       |   |   |   |   |    |    |      |        |       |       |       |       RSEL: registers output multiplexer select
  --                          |       |   |   |   |   |    |    |      |        |       |       |       |       |
  --                          |       |   |   |   |   |    |    |      |        |       |       |       |       |
    case a is              -- DMUX    AI  VP  BR  EI  W    CLI  PD     PCR      MPR     P_OP    ALUOP   REGOP   RSEL
      ------------------------------------
      --            IMPLIED             --
      ------------------------------------
      -- BRK
      when    BRK_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& WRL &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- NOPs         
      when    BRK_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& WRL &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SDW_R & PHR_O; -- PCH->S; SP-1 
      when    BRK_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& WRL &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SDW_R & PLR_O; -- PCL->S; SP-1 
      when    BRK_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& WRL &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SDW_R & ZRD_O; -- Z->S; SP-1; EI 
      when    BRK_OP4 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADSP & NOP_PC & VEC_M & SID_P & NOP_A & SDW_R & PRD_O; -- P->S; VEC->MP; CLI; SEI; CLD
      when    BRK_OP5 => q <= ORD_D &'0'&'1'&'0'&'0'& RDE &'1'& ADMP & LSB_PC & INC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MEM->PCL; MP+1; 1->B; VP
      when    BRK_OP6 => q <= ORD_D &'0'&'1'&'0'&'1'& RDE &'1'& ADMP & MSB_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MEM->PCH; EI; VP 

      -- NOP
      when    NOP_OP0 => q <= NOP_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- EI 

      -- CLC
      when    CLC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & CLC_P & NOP_A & NOP_R & EXT_O; -- 0->C; EI

      -- SEC
      when    SEC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & SEC_P & NOP_A & NOP_R & EXT_O; -- 1->C; EI

      -- CLI
      when    CLI_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & CLI_P & NOP_A & NOP_R & EXT_O; -- 0->I; EI

      -- SEI
      when    SEI_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & SEI_P & NOP_A & NOP_R & EXT_O; -- 1->I; EI

      -- CLV
      when    CLV_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & CLV_P & NOP_A & NOP_R & EXT_O; -- 0->V; EI
      
      -- CLD
      when    CLD_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & CLD_P & NOP_A & NOP_R & EXT_O; -- 0->D; EI

      -- SED
      when    SED_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & SED_P & NOP_A & NOP_R & EXT_O; -- 1->D; EI

      -- TAX
      when    TAX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & NOP_A & XLD_R & ARD_O; -- A->X; EI

      -- TXA
      when    TXA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & NOP_A & ALD_R & XRD_O; -- X->A; EI

      -- TAY
      when    TAY_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & NOP_A & YLD_R & ARD_O; -- A->Y; EI

      -- TYA
      when    TYA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & NOP_A & ALD_R & YRD_O; -- Y->A; EI

      -- TXY
      when    TXY_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & NOP_A & YLD_R & XRD_O; -- X->Y; EI

      -- TYX
      when    TYX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & NOP_A & XLD_R & YRD_O; -- Y->X; EI

      -- TAZ
      when    TAZ_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & ZLD_R & ARD_O; -- A->Z; EI

      -- TZA
      when    TZA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & NOP_A & ALD_R & ZRD_O; -- Z->A; EI

      -- TXS
      when    TXS_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & SLD_R & XRD_O; -- X->S; EI

      -- TSX
      when    TSX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & NOP_A & XLD_R & SRD_O; -- S->X; EI

      -- INC A
      when    INC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & INC_A & ALD_R & ARD_O; -- A+1; EI

      -- DEC A
      when    DEC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & DEC_A & ALD_R & ARD_O; -- A-1; EI
		
      -- INX
      when    INX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & INC_A & XLD_R & XRD_O; -- X+1; EI

      -- DEX
      when    DEX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & DEC_A & XLD_R & XRD_O; -- X-1; EI
      
      -- INY
      when    INY_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & INC_A & YLD_R & YRD_O; -- Y+1; EI

      -- DEY
      when    DEY_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & DEC_A & YLD_R & YRD_O; -- Y-1; EI

      -- PHP
      when    PHP_OP0 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SDW_R & PRD_O; -- P->S; SP-1; EI 

      -- PHA
      when    PHA_OP0 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SDW_R & ARD_O; -- A->S; SP-1; EI 

      -- PHX
      when    PHX_OP0 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SDW_R & XRD_O; -- X->S; SP-1; EI 

      -- PHY
      when    PHY_OP0 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SDW_R & YRD_O; -- X->S; SP-1; EI 

      -- PHR
      when    PHR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& WRE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SDW_R & ARD_O; -- A->S; SP-1;  
      when    PHR_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& WRE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SDW_R & XRD_O; -- X->S; SP-1;  
      when    PHR_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SDW_R & YRD_O; -- Y->S; SP-1; EI 

      -- PLP
      when    PLP_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & SUP_R & EXT_O; -- SP->MP; SP+1 
      when    PLP_OP1 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADSP & NOP_PC & NOP_M & PLD_P & NOP_A & NOP_R & EXT_O; -- S->P; EI 

      -- PLA
      when    PLA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & SUP_R & EXT_O; -- SP->MP; SP+1 
      when    PLA_OP1 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADSP & NOP_PC & NOP_M & FLD_P & NOP_A & ALD_R & EXT_O; -- S->A; EI 

      -- PLX
      when    PLX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & SUP_R & EXT_O; -- SP->MP; SP+1 
      when    PLX_OP1 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADSP & NOP_PC & NOP_M & FLD_P & NOP_A & XLD_R & EXT_O; -- S->X; EI 

      -- PLY
      when    PLY_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & SUP_R & EXT_O; -- SP->MP; SP+1 
      when    PLY_OP1 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADSP & NOP_PC & NOP_M & FLD_P & NOP_A & YLD_R & EXT_O; -- S->Y; EI 

      -- PLR
      when    PLR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & SUP_R & EXT_O; -- SP->MP; SP+1 
      when    PLR_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SYU_R & EXT_O; -- S->Y;  
      when    PLR_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SXU_R & EXT_O; -- S->X;  
      when    PLR_OP3 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & ALD_R & EXT_O; -- S->A; EI

      -- RTI
      when    RTI_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & SUP_R & EXT_O; -- PC->MEM; MP=01XX (STACK)
      when    RTI_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADSP & NOP_PC & NOP_M & PLD_P & NOP_A & SUP_R & EXT_O; -- SP->MEM; MEM->P; SP +1
      when    RTI_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SZU_R & EXT_O; -- S->Z;  
      when    RTI_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; LSB PC->O; SP +1; 
      when    RTI_OP4 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & SUP_R & EXT_O; -- PC->MEM; SP +1; 
      when    RTI_OP5 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADSP & LOD_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; MSB->MP; EI

      -- RTS
      when    RTS_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & SUP_R & EXT_O; -- SP->MEM; SP +1
      when    RTS_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; LSB->O;  
      when    RTS_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SUP_R & EXT_O; -- MP->MEM; SP +1;
      when    RTS_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADSP & LOD_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MEM->PC
      when    RTS_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- PC+1; PC->MEM; EI

      -- ASL (A)
      when    ASL_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLC_P & SHL_A & ALD_R & ARD_O; -- A SHIFT LEFT; EI

      -- LSR (A)
      when    LSR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLC_P & SHR_A & ALD_R & ARD_O; -- A SHIFT RIGHT; EI
      
      -- ROL (A)
      when    ROL_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLC_P & ROL_A & ALD_R & ARD_O; -- A ROTATE LEFT; EI

      -- ROR (A)
      when    ROR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLC_P & ROR_A & ALD_R & ARD_O; -- A ROTATE RIGHT; EI

      -- XYX
      when    XYX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & XRD_O; -- X->O; 
      when    XYX_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & XLD_R & YRD_O; -- Y->X; 
      when    XYX_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & YLD_R & ORD_O; -- O->Y; EI

      -- XAX
      when    XAX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & XRD_O; -- X->O; 
      when    XAX_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & XLD_R & ARD_O; -- A->X; 
      when    XAX_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & ALD_R & ORD_O; -- O->A; EI

      -- XAY
      when    XAY_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & YRD_O; -- Y->O; 
      when    XAY_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & YLD_R & ARD_O; -- A->Y; 
      when    XAY_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & ALD_R & ORD_O; -- O->A; EI

      -- ISP  
      when    ISP_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & SLD_R & XRD_O; -- X->S lsb; 
      when    ISP_OP1 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & SLM_R & ARD_O; -- A->S msb; EI

      -- TSP  
      when    TSP_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & NOP_A & XLD_R & SRD_O; -- S lsb ->X;
      when    TSP_OP1 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLD_P & NOP_A & ALD_R & SRM_O; -- S msb ->A; EI


      ------------------------------------
      --           IMMEDIATE            --
      ------------------------------------
      -- LDA #xx
      when  IMLDA_OP0 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & INC_PC & NOP_M & FLD_P & NOP_A & ALD_R & EXT_O; -- MEM->A; PC +1; EI

      -- LDX #xx
      when  IMLDX_OP0 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & INC_PC & NOP_M & FLD_P & NOP_A & XLD_R & EXT_O; -- MEM->X; PC +1; EI

      -- LDY #yy
      when  IMLDY_OP0 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & INC_PC & NOP_M & FLD_P & NOP_A & YLD_R & EXT_O; -- MEM->Y; PC +1; EI

      -- ADC #xx (immediate)
      when  IMADC_OP0 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & INC_PC & NOP_M & FLV_P & SUM_A & ALD_R & ARD_O; -- A=A+EXT; PC +1; EI
      when  IMADC_OP1 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAA_A & ALD_R & ARD_O; -- A=A+BCD ADJ (DAA); PC +1; EI

      -- SBC #xx (immediate)
      when  IMSBC_OP0 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & INC_PC & NOP_M & FLV_P & SUB_A & ALD_R & ARD_O; -- A=A-EXT; PC +1; EI
      when  IMSBC_OP1 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAS_A & ALD_R & ARD_O; -- A=A-BCD ADJ (DAA); PC +1; EI

      -- CMP #xx (immediate)
      when  IMCMP_OP0 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & INC_PC & NOP_M & FLC_P & CMP_A & NOP_R & ARD_O; -- A-MEM; PC +1; EI

      -- CPX #xx (immediate)
      when  IMCPX_OP0 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & INC_PC & NOP_M & FLC_P & CMP_A & NOP_R & XRD_O; -- X-MEM; PC +1; EI

      -- CPY #xx (immediate)
      when  IMCPY_OP0 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & INC_PC & NOP_M & FLC_P & CMP_A & NOP_R & YRD_O; -- Y-MEM; PC +1; EI

      -- AND #xx (immediate)
      when  IMAND_OP0 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & INC_PC & NOP_M & FLD_P & AND_A & ALD_R & ARD_O; -- A AND MEM -> A; PC +1;

      -- ORA #xx (immediate)
      when  IMORA_OP0 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & INC_PC & NOP_M & FLD_P &  OR_A & ALD_R & ARD_O; -- A OR MEM -> A; PC +1;

      -- EOR #xx (immediate)
      when  IMEOR_OP0 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & INC_PC & NOP_M & FLD_P & XOR_A & ALD_R & ARD_O; -- A XOR MEM -> A; PC +1;

      -- BIT #xx (immediate)
      when  IMBRK_OP0 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & INC_PC & NOP_M & LDZ_P & BIT_A & NOP_R & ARD_O; -- A AND MEM; PC +1;

		
      ------------------------------------
      --           ZERO PAGE            --
      ------------------------------------
      -- LDA $xx (zero page)      
      when  ZPLDA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPLDA_OP1 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & INC_PC & NOP_M & FLD_P & NOP_A & ALD_R & EXT_O; -- MP->MEM; MEM->A; PC+1; EI

      -- LDX $xx (zero page)      
      when  ZPLDX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPLDX_OP1 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & INC_PC & NOP_M & FLD_P & NOP_A & XLD_R & EXT_O; -- MP->MEM; MEM->X; PC+1; EI

      -- LDY $xx (zero page)      
      when  ZPLDY_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPLDY_OP1 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & INC_PC & NOP_M & FLD_P & NOP_A & YLD_R & EXT_O; -- MP->MEM; MEM->Y; PC+1; EI

      -- STA $xx (zero page)      
      when  ZPSTA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPSTA_OP1 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & INC_PC & NOP_M & NOP_P & NOP_A & NOP_R & ARD_O; -- MP->MEM; A->MEM; PC+1; EI

      -- STX $xx (zero page)      
      when  ZPSTX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPSTX_OP1 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & INC_PC & NOP_M & NOP_P & NOP_A & NOP_R & XRD_O; -- MP->MEM; X->MEM; PC+1; EI

      -- STY $xx (zero page)      
      when  ZPSTY_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPSTY_OP1 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & INC_PC & NOP_M & NOP_P & NOP_A & NOP_R & YRD_O; -- MP->MEM; Y->MEM; PC+1; EI

      -- STZ $xx (zero page)      
      when  ZPSTZ_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPSTZ_OP1 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & INC_PC & NOP_M & NOP_P & NOP_A & NOP_R & Z00_O; -- MP->MEM; 0->MEM; PC+1; EI

      -- ADC $xx (zero page)
      when  ZPADC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPADC_OP1 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLV_P & SUM_A & ALD_R & ARD_O; -- A=A+MEM; EI
      when  ZPADC_OP2 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAA_A & ALD_R & ARD_O; -- A=A+BCD ADJ (DAA); PC +1; EI

      -- SBC $xx (zero page)
      when  ZPSBC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPSBC_OP1 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLV_P & SUB_A & ALD_R & ARD_O; -- A=A-MEM; EI
      when  ZPSBC_OP2 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAS_A & ALD_R & ARD_O; -- A=A-BCD ADJ (DAS); PC +1; EI

      -- CMP $xx (zeropage)
      when  ZPCMP_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPCMP_OP1 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & CMP_A & NOP_R & ARD_O; -- A-MEM; EI

      -- CPX $xx (zeropage)
      when  ZPCPX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPCPX_OP1 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & CMP_A & NOP_R & XRD_O; -- X-MEM; EI

      -- CPY $xx (zeropage)
      when  ZPCPY_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPCPY_OP1 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & CMP_A & NOP_R & YRD_O; -- Y-MEM; EI

      -- AND $xx (zeropage)
      when  ZPAND_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPAND_OP1 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & AND_A & ALD_R & ARD_O; -- A = A AND MEM;  EI

      -- ORA $xx (zeropage)
      when  ZPORA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPORA_OP1 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P &  OR_A & ALD_R & ARD_O; -- A = A OR MEM;  EI

      -- EOR $xx (zeropage)
      when  ZPEOR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPEOR_OP1 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & XOR_A & ALD_R & ARD_O; -- A = A XOR MEM;  EI

      -- BIT $xx (zero page)      
      when  ZPBIT_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPBIT_OP1 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & INC_PC & NOP_M & FLD_P & BIT_A & NOP_R & ARD_O; -- MP->MEM; MEM->ALU; PC+1; EI

      -- ASL $xx (zero page)
      when  ZPASL_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPASL_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1; EI
      when  ZPASL_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & SHL_A & OLD_R & ORD_O; -- O SHIFT LEFT;
      when  ZPASL_OP3 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1; EI

      -- LSR $xx (zero page)
      when  ZPLSR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPLSR_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1; EI
      when  ZPLSR_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & SHR_A & OLD_R & ORD_O; -- O SHIFT RIGHT;
      when  ZPLSR_OP3 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1; EI

      -- ROL $xx (zero page)
      when  ZPROL_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPROL_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1; EI
      when  ZPROL_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & ROL_A & OLD_R & ORD_O; -- O ROTATE LEFT;
      when  ZPROL_OP3 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1; EI

      -- ROR $xx (zero page)
      when  ZPROR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPROR_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1; EI
      when  ZPROR_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & ROR_A & OLD_R & ORD_O; -- O ROTATE RIGHT;
      when  ZPROR_OP3 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1; EI

      -- INC $xx (zero page)
      when  ZPINC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPINC_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1; EI
      when  ZPINC_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & INC_A & OLD_R & ORD_O; -- O = O +1     
      when  ZPINC_OP3 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1; EI

      -- DEC $xx (zero page)
      when  ZPDEC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPDEC_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1; EI
      when  ZPDEC_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & DEC_A & OLD_R & ORD_O; -- O = O -1    
      when  ZPDEC_OP3 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1; EI

      -- TSB $xx (zero page)
      when  ZPTSB_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPTSB_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1; EI
      when  ZPTSB_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & LDZ_P & AND_A & NOP_R & ARD_O; -- A AND O -> Z
      when  ZPTSB_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & TSB_A & OLD_R & ARD_O; -- A OR O -> O
      when  ZPTSB_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1; EI

      -- TRB $xx (zero page)
      when  ZPTRB_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  ZPTRB_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1; EI
      when  ZPTRB_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & LDZ_P & AND_A & NOP_R & ARD_O; -- A AND O -> Z
      when  ZPTRB_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & TRB_A & OLD_R & ARD_O; -- A NAND O -> O
      when  ZPTRB_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1; EI
		
      ------------------------------------
      --          ZERO PAGE,X           --
      ------------------------------------
      -- LDA $xx,X (zero page indexed)
      when  ZXLDA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP;
      when  ZXLDA_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP-+=X; PC+1;
      when  ZXLDA_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & NOP_A & ALD_R & EXT_O; -- MP->MEM; MEM->A; EI

      -- LDY $xx,X (zero page indexed)
      when  ZXLDY_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP;
      when  ZXLDY_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP+=X; PC+1;
      when  ZXLDY_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & NOP_A & YLD_R & EXT_O; -- MP->MEM; MEM->Y; EI

      -- STA $xx,X (zero page indexed)
      when  ZXSTA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP;
      when  ZXSTA_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP+=X; PC+1;
      when  ZXSTA_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ARD_O; -- MP->MEM; A->MEM; EI

      -- STY $xx,X (zero page indexed)
      when  ZXSTY_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP;
      when  ZXSTY_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP+=X; PC+1;
      when  ZXSTY_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & YRD_O; -- MP->MEM; Y->MEM; EI

      -- STZ $xx,X (zero page indexed)
      when  ZXSTZ_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP;
      when  ZXSTZ_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP+=X; PC+1;
      when  ZXSTZ_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & Z00_O; -- MP->MEM; X->MEM; EI

      -- ADC $xx,X (zero page indexed)
      when  ZXADC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP; PC+1
      when  ZXADC_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP+=X; PC+1;
      when  ZXADC_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLV_P & SUM_A & ALD_R & ARD_O; -- A=A+MEM; EI
      when  ZXADC_OP3 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAA_A & ALD_R & ARD_O; -- A=A+BCD ADJ (DAA); EI

      -- SBC $xx,X (zero page indexed)
      when  ZXSBC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP; PC+1
      when  ZXSBC_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP+=X; PC+1;
      when  ZXSBC_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLV_P & SUB_A & ALD_R & ARD_O; -- A=A-MEM; EI
      when  ZXSBC_OP3 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAS_A & ALD_R & ARD_O; -- A=A-BCD ADJ (DAS); EI

      -- CMP $xx,X (zero page indexed)
      when  ZXCMP_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP; PC+1
      when  ZXCMP_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP-+=X; PC+1;
      when  ZXCMP_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & CMP_A & NOP_R & ARD_O; -- A-MEM; EI

      -- AND $xx,X (zero page indexed)
      when  ZXAND_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP; PC+1
      when  ZXAND_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP-+=X; PC+1;
      when  ZXAND_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & AND_A & ALD_R & ARD_O; -- A = A AND MEM;  EI

      -- ORA $xx,X (zero page indexed)
      when  ZXORA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP; PC+1
      when  ZXORA_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP-+=X; PC+1;
      when  ZXORA_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P &  OR_A & ALD_R & ARD_O; -- A = A OR MEM;  EI

      -- EOR $xx,X (zero page indexed)
      when  ZXEOR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP;
      when  ZXEOR_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP-+=X; PC+1;
      when  ZXEOR_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & XOR_A & ALD_R & ARD_O; -- A = A XOR MEM;  EI

      -- ASL $xx,X (zero page indexed)
      when  ZXASL_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP;
      when  ZXASL_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP+=X PC+1;
      when  ZXASL_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; 
      when  ZXASL_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & SHL_A & OLD_R & ORD_O; -- O SHIFT LEFT;
      when  ZXASL_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; EI

      -- LSR $xx,X (zero page indexed)
      when  ZXLSR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP
      when  ZXLSR_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP+=X; PC+1;
      when  ZXLSR_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O;
      when  ZXLSR_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & SHR_A & OLD_R & ORD_O; -- O SHIFT RIGHT;
      when  ZXLSR_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; EI

      -- ROL $xx,X (zero page indexed)
      when  ZXROL_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP;
      when  ZXROL_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP+=X; PC+1;
      when  ZXROL_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O;
      when  ZXROL_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & ROL_A & OLD_R & ORD_O; -- O ROTATE LEFT;
      when  ZXROL_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; EI

      -- ROR $xx,X (zero page indexed)
      when  ZXROR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP;
      when  ZXROR_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP+=X; PC+1;
      when  ZXROR_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O;
      when  ZXROR_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & ROR_A & OLD_R & ORD_O; -- O ROTATE RIGHT;
      when  ZXROR_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; EI

      -- INC $xx,X (zero page indexed)
      when  ZXINC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP;
      when  ZXINC_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP+=X; PC+1;
      when  ZXINC_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O;
      when  ZXINC_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & INC_A & OLD_R & ORD_O; -- O = O +1 
      when  ZXINC_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; EI

      -- DEC $xx,X (zero page indexed)
      when  ZXDEC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP;
      when  ZXDEC_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP+=X; PC+1;
      when  ZXDEC_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O;
      when  ZXDEC_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & DEC_A & OLD_R & ORD_O; -- O = O -1 
      when  ZXDEC_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; EI

      -- BIT $xx,X (zero page indexed)
      when  ZXBIT_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP; PC+1
      when  ZXBIT_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & XRD_O; -- MP-+=X; PC+1;
      when  ZXBIT_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & BIT_A & NOP_R & ARD_O; -- A = A AND MEM;  EI
		
      ------------------------------------
      --          ZERO PAGE,Y           --
      ------------------------------------
      -- LDX $xx,Y (zero page indexed)
      when  ZYLDX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP;
      when  ZYLDX_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & YRD_O; -- MP+=Y; PC+1;
      when  ZYLDX_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & NOP_A & XLD_R & EXT_O; -- MP->MEM; MEM->X; EI

      -- STX $xx,Y (zero page indexed)
      when  ZYSTX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & OLD_R & EXT_O; -- ZP->MP;
      when  ZYSTX_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & SWC_A & NOP_R & YRD_O; -- MP+=Y; PC+1;
      when  ZYSTX_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & XRD_O; -- MP->MEM; X->MEM; EI

      ------------------------------------
      --           INDIRECT             --
      ------------------------------------
      -- JMP ($xxxx) (indirect)
      when  INJMP_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  INJMP_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  INJMP_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & INC_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; MP+1
      when  INJMP_OP3 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & LOD_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MEM->PC; O->PC; EI

      ------------------------------------
      --          INDIRECT,Y            --
      ------------------------------------
      -- LDA ($xx),Y (zeropage - indirect - indexed)
      when  IYLDA_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  IYLDA_OP1 => q <= EXT_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & INC_M & AUC_P & SWC_A & OLD_R & YRD_O; -- MP->MEM; MEM+Y->O; (LSB POINTER)
      when  IYLDA_OP2 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & HAC_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; MEM->MP; (MSB POINTER)
      when  IYLDA_OP3 => q <= ORD_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & ICC_M & FLD_P & NOP_A & ALD_R & EXT_O; -- O->MP; (LSB POINTER)
      when  IYLDA_OP4 => q <= ORD_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & NOP_A & ALD_R & EXT_O; -- MP->MEM; MEM->A; EI

      -- STA ($xx),Y (zeropage - indirect - indexed)
      when  IYSTA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  IYSTA_OP1 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & INC_M & AUC_P & SWC_A & OLD_R & YRD_O; -- MP->MEM; MEM+Y->O; (LSB POINTER)
      when  IYSTA_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & HAC_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; MEM->MP; (MSB POINTER)
      when  IYSTA_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- O->MP; (LSB POINTER)
      when  IYSTA_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ARD_O; -- MP->MEM; A->MEM; EI

      -- ADC ($xx),Y (zeropage - indirect - indexed)
      when  IYADC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  IYADC_OP1 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & INC_M & AUC_P & SWC_A & OLD_R & YRD_O; -- MP->MEM; MEM+Y->O; (LSB POINTER)
      when  IYADC_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & HAC_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; MEM->MP; (MSB POINTER)
      when  IYADC_OP3 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP + CARRY
      when  IYADC_OP4 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLV_P & SUM_A & ALD_R & ARD_O; -- MP->MEM; A=A+EXT
      when  IYADC_OP5 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAA_A & ALD_R & ARD_O; -- A=A+BCD ADJ (DAA); PC +1; EI

      -- SBC ($xx),Y (zeropage - indirect - indexed)
      when  IYSBC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  IYSBC_OP1 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & INC_M & AUC_P & SWC_A & OLD_R & YRD_O; -- MP->MEM; MEM+Y->O; (LSB POINTER)
      when  IYSBC_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & HAC_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; MEM->MP; (MSB POINTER)
      when  IYSBC_OP3 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP + CARRY
      when  IYSBC_OP4 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLV_P & SUB_A & ALD_R & ARD_O; -- MP->MEM; A=A-EXT
      when  IYSBC_OP5 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAS_A & ALD_R & ARD_O; -- A=A+BCD ADJ (DAS); PC +1; EI

      -- CMP ($xx),Y (zeropage - indirect - indexed)
      when  IYCMP_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  IYCMP_OP1 => q <= EXT_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & INC_M & AUC_P & SWC_A & OLD_R & YRD_O; -- MP->MEM; MEM+Y->O; (LSB POINTER)
      when  IYCMP_OP2 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & HAC_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; MEM->MP; (MSB POINTER)
      when  IYCMP_OP3 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & ICC_M & FLC_P & CMP_A & NOP_R & ARD_O; -- MP->MEM; A-MEM MP_MSB+CARRY, EI
      when  IYCMP_OP4 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & CMP_A & NOP_R & ARD_O; -- MP->MEM;  A-MEM; EI

      -- AND ($xx),Y (zeropage - indirect - indexed)
      when  IYAND_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  IYAND_OP1 => q <= EXT_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & INC_M & AUC_P & SWC_A & OLD_R & YRD_O; -- MP->MEM; MEM+Y->O; (LSB POINTER)
      when  IYAND_OP2 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & HAC_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; MEM->MP; (MSB POINTER)
      when  IYAND_OP3 => q <= EXT_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP + CARRY
      when  IYAND_OP4 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & AND_A & ALD_R & ARD_O; -- A = A AND MEM; EI

      -- ORA ($xx),Y (zeropage - indirect - indexed)
      when  IYORA_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  IYORA_OP1 => q <= EXT_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & INC_M & AUC_P & SWC_A & OLD_R & YRD_O; -- MP->MEM; MEM+Y->O; (LSB POINTER)
      when  IYORA_OP2 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & HAC_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; MEM->MP; (MSB POINTER)
      when  IYORA_OP3 => q <= EXT_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP + CARRY
      when  IYORA_OP4 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P &  OR_A & ALD_R & ARD_O; -- A = A OR MEM; EI

      -- EOR ($xx),Y (zeropage - indirect - indexed)
      when  IYEOR_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ZPL_M & NOP_P & NOP_A & NOP_R & EXT_O; -- ZP->MP; PC+1
      when  IYEOR_OP1 => q <= EXT_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & INC_PC & INC_M & AUC_P & SWC_A & OLD_R & YRD_O; -- MP->MEM; MEM+Y->O; (LSB POINTER)
      when  IYEOR_OP2 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & HAC_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; MEM->MP; (MSB POINTER)
      when  IYEOR_OP3 => q <= EXT_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP + CARRY
      when  IYEOR_OP4 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & XOR_A & ALD_R & ARD_O; -- A = A XOR MEM; EI

      ------------------------------------
      --          INDIRECT,X            --
      ------------------------------------
      -- LDA ($xx,X) (zero page - indexed - indirect)
      when  IXLDA_OP0 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & SWC_A & NOP_R & XRD_O; -- ZP+X->MP; PC+1
      when  IXLDA_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & INC_M & NOP_P & NOP_A & OLD_R & EXT_O; -- O<=LSB; MP+=1
      when  IXLDA_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP<=MSB & LSB (O)
      when  IXLDA_OP3 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & NOP_A & ALD_R & EXT_O; -- MP->MEM; MEM->A; EI=1

      -- STA ($xx,X) (zero page - indexed - indirect)
      when  IXSTA_OP0 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & SWC_A & NOP_R & XRD_O; -- ZP+X->MP; PC+1
      when  IXSTA_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & INC_M & NOP_P & NOP_A & OLD_R & EXT_O; -- O<=LSB; MP+=1
      when  IXSTA_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP<=MSB & LSB (O)
      when  IXSTA_OP3 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ARD_O; -- A->MEM; EI=1

      -- AND ($xx,X) (zero page - indexed - indirect)
      when  IXAND_OP0 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & SWC_A & NOP_R & XRD_O; -- ZP+X->MP; PC+1
      when  IXAND_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & INC_M & NOP_P & NOP_A & OLD_R & EXT_O; -- O<=LSB; MP+=1
      when  IXAND_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP<=MSB & LSB (O)
      when  IXAND_OP3 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & AND_A & ALD_R & ARD_O; -- MP->MEM; A=A AND MEM; EI=1

      -- ORA ($xx,X) (zero page - indexed - indirect)
      when  IXORA_OP0 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & SWC_A & NOP_R & XRD_O; -- ZP+X->MP; PC+1
      when  IXORA_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & INC_M & NOP_P & NOP_A & OLD_R & EXT_O; -- O<=LSB; MP+=1
      when  IXORA_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP<=MSB & LSB (O)
      when  IXORA_OP3 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P &  OR_A & ALD_R & ARD_O; -- MP->MEM; A=A OR MEM; EI=1

      -- EOR ($xx,X) (zero page - indexed - indirect)
      when  IXEOR_OP0 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & SWC_A & NOP_R & XRD_O; -- ZP+X->MP; PC+1
      when  IXEOR_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & INC_M & NOP_P & NOP_A & OLD_R & EXT_O; -- O<=LSB; MP+=1
      when  IXEOR_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP<=MSB & LSB (O)
      when  IXEOR_OP3 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & XOR_A & ALD_R & ARD_O; -- MP->MEM; A=A XOR MEM; EI=1

      -- ADC ($xx,X) (zero page - indexed - indirect)
      when  IXADC_OP0 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & SWC_A & NOP_R & XRD_O; -- ZP+X->MP; PC+1
      when  IXADC_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & INC_M & NOP_P & NOP_A & OLD_R & EXT_O; -- O<=LSB; MP+=1
      when  IXADC_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP<=MSB & LSB (O)
      when  IXADC_OP3 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLV_P & SUM_A & ALD_R & ARD_O; -- MP->MEM; A=A XOR MEM; EI=1
      when  IXADC_OP4 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAA_A & ALD_R & ARD_O; -- A=A+BCD ADJ (DAA); PC +1; EI

      -- SBC ($xx,X) (zero page - indexed - indirect)
      when  IXSBC_OP0 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & SWC_A & NOP_R & XRD_O; -- ZP+X->MP; PC+1
      when  IXSBC_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & INC_M & NOP_P & NOP_A & OLD_R & EXT_O; -- O<=LSB; MP+=1
      when  IXSBC_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP<=MSB & LSB (O)
      when  IXSBC_OP3 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLV_P & SUB_A & ALD_R & ARD_O; -- MP->MEM; A=A XOR MEM; EI=1
      when  IXSBC_OP4 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAS_A & ALD_R & ARD_O; -- A=A+BCD ADJ (DAA); PC +1; EI

      -- CMP ($xx,X) (zero page - indexed - indirect)
      when  IXCMP_OP0 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ZPL_M & NOP_P & SWC_A & NOP_R & XRD_O; -- ZP+X->MP; PC+1
      when  IXCMP_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & INC_M & NOP_P & NOP_A & OLD_R & EXT_O; -- O<=LSB; MP+=1
      when  IXCMP_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ALL_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP<=MSB & LSB (O)
      when  IXCMP_OP3 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & CMP_A & NOP_R & ARD_O; -- MP->MEM; A=A XOR MEM; EI=1

      -- JMP ($xxxx,X) (absolute indexed - indirect)
      when  IXJMP_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  IXJMP_OP1 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  IXJMP_OP2 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MEM->A; MP_MSB+CARRY, EI
      when  IXJMP_OP3 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & INM_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; EI
      when  IXJMP_OP4 => q <= ORD_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & LOD_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->PC; O->PC; EI

      -- JSR ($xxxx,X) (absolute indexed - indirect)
      when  IXJSR_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  IXJSR_OP1 => q <= ORD_D &'1'&'0'&'0'&'0'& WRE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SDW_R & PHR_O; -- PCH->S; SP-1; 
      when  IXJSR_OP2 => q <= ORD_D &'1'&'0'&'0'&'0'& WRE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SDW_R & PLR_O; -- PCL->S; SP-1; 
      when  IXJSR_OP3 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & NOP_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  IXJSR_OP4 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & INM_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; EI
      when  IXJSR_OP5 => q <= ORD_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & LOD_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->PC; O->PC; EI

      ------------------------------------
      --           ABSOLUTE             --
      ------------------------------------
      -- LDA $xxxx (absolute)
      when  ABLDA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABLDA_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABLDA_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & NOP_A & ALD_R & EXT_O; -- MP->MEM; MEM->A; PC+1

      -- LDX $xxxx (absolute)
      when  ABLDX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABLDX_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABLDX_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & NOP_A & XLD_R & EXT_O; -- MP->MEM; MEM->X; PC+1

      -- LDY $xxxx (absolute)
      when  ABLDY_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABLDY_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABLDY_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & NOP_A & YLD_R & EXT_O; -- MP->MEM; MEM->Y; PC+1

      -- STA $xxxx (absolute)
      when  ABSTA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABSTA_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABSTA_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ARD_O; -- MP->MEM; A->MEM; PC+1

      -- STX $xxxx (absolute)
      when  ABSTX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABSTX_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABSTX_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & XRD_O; -- MP->MEM; X->MEM; PC+1

      -- STY $xxxx (absolute)
      when  ABSTY_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABSTY_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABSTY_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & YRD_O; -- MP->MEM; Y->MEM; PC+1

      -- STZ $xxxx (absolute)
      when  ABSTZ_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABSTZ_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABSTZ_OP2 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & Z00_O; -- MP->MEM; 0->MEM; PC+1
      
      -- JMP $xxxx (absolute)
      when  ABJMP_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- LSB->O; PC+1
      when  ABJMP_OP1 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & LOD_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->PC; O->PC; EI

      -- JSR $xxxx (absolute)
      when  ABJSR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- LSB->O; PC+1
      when  ABJSR_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& WRE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SDW_R & PHR_O; -- PCH->S; SP-1; 
      when  ABJSR_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& WRE &'0'& ADSP & NOP_PC & NOP_M & NOP_P & NOP_A & SDW_R & PLR_O; -- PCL->S; SP-1; 
      when  ABJSR_OP3 => q <= ORD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & LOD_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->PC; O->PC; EI

      -- BIT $xxxx (absolute)
      when  ABBIT_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABBIT_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABBIT_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & BIT_A & NOP_R & ARD_O; -- MP->MEM; MEM->ALU; PC+1

      -- ADC $xxxx (absolute)
      when  ABADC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABADC_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABADC_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLV_P & SUM_A & ALD_R & ARD_O; -- A=A+EXT; EI
      when  ABADC_OP3 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAA_A & ALD_R & ARD_O; -- A=A+BCD ADJ (DAA); PC +1; EI

      -- SBC $xxxx (absolute)
      when  ABSBC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABSBC_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABSBC_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLV_P & SUB_A & ALD_R & ARD_O; -- A=A-EXT; EI
      when  ABSBC_OP3 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAS_A & ALD_R & ARD_O; -- A=A-BCD ADJ (DAA); PC +1; EI

      -- CMP $xxxx (absolute)
      when  ABCMP_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABCMP_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABCMP_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & CMP_A & NOP_R & ARD_O; -- A-EXT; EI

      -- CPX $xxxx (absolute)
      when  ABCPX_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABCPX_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABCPX_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & CMP_A & NOP_R & XRD_O; -- X-EXT; EI

      -- CPY $xxxx (absolute)
      when  ABCPY_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABCPY_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABCPY_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & CMP_A & NOP_R & YRD_O; -- Y-EXT; EI

      -- ORA $xxxx (absolute)
      when  ABORA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABORA_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABORA_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P &  OR_A & ALD_R & ARD_O; -- A=A OR MEM; EI

      -- AND $xxxx (absolute)
      when  ABAND_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABAND_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABAND_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & AND_A & ALD_R & ARD_O; -- A=A AND MEM; EI

      -- EOR $xxxx (absolute)
      when  ABEOR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABEOR_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABEOR_OP2 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & XOR_A & ALD_R & ARD_O; -- A=A XOR MEM; EI

      -- ASL $xxxx (absolute)
      when  ABASL_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABASL_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABASL_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1
      when  ABASL_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & SHL_A & OLD_R & ORD_O; -- O SHIFT LEFT;
      when  ABASL_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1

      -- LSR $xxxx (absolute)
      when  ABLSR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABLSR_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABLSR_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1
      when  ABLSR_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & SHR_A & OLD_R & ORD_O; -- O SHIFT RIGHT;
      when  ABLSR_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1

      -- ROL $xxxx (absolute)
      when  ABROL_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABROL_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABROL_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1
      when  ABROL_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & ROL_A & OLD_R & ORD_O; -- O ROTATE LEFT;
      when  ABROL_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1

      -- ROR $xxxx (absolute)
      when  ABROR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABROR_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABROR_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1
      when  ABROR_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & ROR_A & OLD_R & ORD_O; -- O ROTATE RIGHT;
      when  ABROR_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1

      -- INC $xxxx (absolute)
      when  ABINC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABINC_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABINC_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1
      when  ABINC_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & INC_A & OLD_R & ORD_O; -- O = O +1
      when  ABINC_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1

      -- DEC $xxxx (absolute)
      when  ABDEC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABDEC_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABDEC_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1
      when  ABDEC_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & DEC_A & OLD_R & ORD_O; -- O = O -1
      when  ABDEC_OP4 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1

      -- TSB $xxxx (absolute)
      when  ABTSB_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABTSB_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABTSB_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1
      when  ABTSB_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & LDZ_P & AND_A & NOP_R & ARD_O; -- A AND O -> Z
      when  ABTSB_OP4 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & TSB_A & OLD_R & ARD_O; -- A OR O => O
      when  ABTSB_OP5 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1

      -- TRB $xxxx (absolute)
      when  ABTRB_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & LSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- LSB->MP; PC+1
      when  ABTRB_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & MSB_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MSB->MP; PC+1
      when  ABTRB_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; PC+1
      when  ABTRB_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & LDZ_P & AND_A & NOP_R & ARD_O; -- A AND O -> Z
      when  ABTRB_OP4 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & TRB_A & OLD_R & ARD_O; -- A NAND O => O
      when  ABTRB_OP5 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; PC+1
		
      ------------------------------------
      --          ABSOLUTE,X            --
      ------------------------------------
      --                      DMUX: ALU operand #2 multiplexer
      --                      |       AI: effective address is indexed (X or Y)
      --                      |       |   VP: vector pull
      --                      |       |   |   BR: branch opcode
      --                      |       |   |   |   EI: end of microcode sequence (the hidden extra cycle it's always executed after this microinstruction) 
      --                      |       |   |   |   |   W: read/write control
      --                      |       |   |   |   |   |    CLI: clear interrupt request
      --                      |       |   |   |   |   |    |    PD: PC/MP address output multiplexer select
      --                      |       |   |   |   |   |    |    |      PCR: register PC (program counter)
      --                      |       |   |   |   |   |    |    |      |        MPR: register MP (memory pointer)
      --                      |       |   |   |   |   |    |    |      |        |       P_OP: register P set/reset bit
      --                      |       |   |   |   |   |    |    |      |        |       |       ALUOP: ALU operation
      --                      |       |   |   |   |   |    |    |      |        |       |       |       REGOP: registers load/increment/decrement etc.
      --                      |       |   |   |   |   |    |    |      |        |       |       |       |       RSEL: registers output multiplexer select
      --                      |       |   |   |   |   |    |    |      |        |       |       |       |       |
      --                      |       |   |   |   |   |    |    |      |        |       |       |       |       |
      --                   -- DMUX    AI  VP  BR  EI  W    CLI  PD     PCR      MPR     P_OP    ALUOP   REGOP   RSEL
      -- LDA $xxxx,X (absolute indexed)
      when  AXLDA_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXLDA_OP1 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXLDA_OP2 => q <= ORD_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & ICC_M & FLD_P & NOP_A & ALD_R & EXT_O; -- MP->MEM; MEM->A; MP_MSB+CARRY, EI
      when  AXLDA_OP3 => q <= ORD_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & NOP_A & ALD_R & EXT_O; -- MP->MEM; MEM->A; EI

      -- LDY $xxxx,X (absolute indexed)
      when  AXLDY_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXLDY_OP1 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXLDY_OP2 => q <= ORD_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & ICC_M & FLD_P & NOP_A & YLD_R & EXT_O; -- MP->MEM; MEM->Y, MP_MSB+CARRY, EI
      when  AXLDY_OP3 => q <= ORD_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & NOP_A & YLD_R & EXT_O; -- MP->MEM; MEM->Y; EI

      -- STA $xxxx,X (absolute indexed)
      when  AXSTA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXSTA_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXSTA_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MP_MSB+CARRY, EI
      when  AXSTA_OP3 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ARD_O; -- MP->MEM; A->MEM; EI

      -- STZ $xxxx,X (absolute indexed)
      when  AXSTZ_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXSTZ_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXSTZ_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MP_MSB+CARRY, EI
      when  AXSTZ_OP3 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & Z00_O; -- MP->MEM; 0->MEM; EI

      -- ADC $xxxx,X (absolute indexed)
      when  AXADC_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXADC_OP1 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXADC_OP2 => q <= EXT_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; A=A+EXT; MP_MSB+CARRY, EI
      when  AXADC_OP3 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLV_P & SUM_A & ALD_R & ARD_O; -- MP->MEM; A=A+EXT
      when  AXADC_OP4 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAA_A & ALD_R & ARD_O; -- A=A+BCD ADJ (DAA); PC +1; EI

      -- SBC $xxxx,X (absolute indexed)
      when  AXSBC_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXSBC_OP1 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXSBC_OP2 => q <= EXT_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; A=A-EXT; MP_MSB+CARRY, EI
      when  AXSBC_OP3 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLV_P & SUB_A & ALD_R & ARD_O; -- MP->MEM; A=A-EXT
      when  AXSBC_OP4 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAS_A & ALD_R & ARD_O; -- A=A-BCD ADJ (DAS); PC +1; EI

      -- CMP $xxxx,X (absolute indexed)
      when  AXCMP_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXCMP_OP1 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXCMP_OP2 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & ICC_M & FLC_P & CMP_A & NOP_R & ARD_O; -- MP->MEM; A-MEM MP_MSB+CARRY, EI
      when  AXCMP_OP3 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & CMP_A & NOP_R & ARD_O; -- MP->MEM; A-MEM; EI

      -- INC $xxxx,X (absolute indexed)
      when  AXINC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXINC_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXINC_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MP_MSB+CARRY, EI
      when  AXINC_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; EI
      when  AXINC_OP4 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & INC_A & OLD_R & ORD_O; -- O = O +1     
      when  AXINC_OP5 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; EI

      -- DEC $xxxx,X (absolute indexed)
      when  AXDEC_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXDEC_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXDEC_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MP_MSB+CARRY, EI
      when  AXDEC_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; EI
      when  AXDEC_OP4 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & DEC_A & OLD_R & ORD_O; -- O = O -1     
      when  AXDEC_OP5 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; EI

      -- ASL $xxxx,X (absolute indexed)
      when  AXASL_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXASL_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXASL_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MP_MSB+CARRY, EI
      when  AXASL_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; EI
      when  AXASL_OP4 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & SHL_A & OLD_R & ORD_O; -- O SHIFT LEFT 
      when  AXASL_OP5 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; EI

      -- LSR $xxxx,X (absolute indexed)
      when  AXLSR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXLSR_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXLSR_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MP_MSB+CARRY, EI
      when  AXLSR_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; EI
      when  AXLSR_OP4 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & SHR_A & OLD_R & ORD_O; -- O SHIFT RIGHT
      when  AXLSR_OP5 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; EI

      -- ROL $xxxx,X (absolute indexed)
      when  AXROL_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXROL_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXROL_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MP_MSB+CARRY, EI
      when  AXROL_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; EI
      when  AXROL_OP4 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & ROL_A & OLD_R & ORD_O; -- O ROTATE LEFT 
      when  AXROL_OP5 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; EI

      -- ROR $xxxx,X (absolute indexed)
      when  AXROR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXROR_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXROR_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MP_MSB+CARRY, EI
      when  AXROR_OP3 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MP->MEM; MEM->O; EI
      when  AXROR_OP4 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & ROR_A & OLD_R & ORD_O; -- O ROTATE RIGHT
      when  AXROR_OP5 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ORD_O; -- MP->MEM; O->MEM; EI

      -- AND $xxxx,X (absolute indexed)
      when  AXAND_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXAND_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXAND_OP2 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MP_MSB+CARRY, EI
      when  AXAND_OP3 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & AND_A & ALD_R & ARD_O; -- MP->MEM; EXT AND A; EI

      -- ORA $xxxx,X (absolute indexed)
      when  AXORA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXORA_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXORA_OP2 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MP_MSB+CARRY, EI
      when  AXORA_OP3 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P &  OR_A & ALD_R & ARD_O; -- MP->MEM; EXT OR A; EI

      -- EOR $xxxx,X (absolute indexed)
      when  AXEOR_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXEOR_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXEOR_OP2 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MP_MSB+CARRY, EI
      when  AXEOR_OP3 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & XOR_A & ALD_R & ARD_O; -- MP->MEM; EXT XOR A; EI

      -- BIT $xxxx,X (absolute indexed)
      when  AXBIT_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AXBIT_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & XRD_O; -- MEM->MP_MSB; MEM->O+X->MP_LSB; PC+1;
      when  AXBIT_OP2 => q <= EXT_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MP_MSB+CARRY, EI
      when  AXBIT_OP3 => q <= EXT_D &'0'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & BIT_A & NOP_R & ARD_O; -- MP->MEM; EXT BIT A; EI
		
      ------------------------------------
      --          ABSOLUTE,Y            --
      ------------------------------------
      -- LDA $xxxx,X (absolute indexed)
      when  AYLDA_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AYLDA_OP1 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & YRD_O; -- MEM->MP_MSB; MEM->O+Y->MP_LSB; PC+1;
      when  AYLDA_OP2 => q <= ORD_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & ICC_M & FLD_P & NOP_A & ALD_R & EXT_O; -- MP->MEM; MEM->A; MP_MSB+CARRY, EI
      when  AYLDA_OP3 => q <= ORD_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & NOP_A & ALD_R & EXT_O; -- MP->MEM; MEM->A; EI

      -- LDX $xxxx,Y (absolute indexed)
      when  AYLDX_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AYLDX_OP1 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & YRD_O; -- MEM->MP_MSB; MEM->O+Y->MP_LSB; PC+1;
      when  AYLDX_OP2 => q <= ORD_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & ICC_M & FLD_P & NOP_A & XLD_R & EXT_O; -- MP->MEM; MEM->X; MP_MSB+CARRY, EI
      when  AYLDX_OP3 => q <= ORD_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & NOP_A & XLD_R & EXT_O; -- MP->MEM; MEM->X; EI

      -- STA $xxxx,Y (absolute indexed)
      when  AYSTA_OP0 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AYSTA_OP1 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & YRD_O; -- MEM->MP_MSB; MEM->O+Y->MP_LSB; PC+1;
      when  AYSTA_OP2 => q <= ORD_D &'0'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; MP_MSB+CARRY, EI
      when  AYSTA_OP3 => q <= ORD_D &'0'&'0'&'0'&'1'& WRE &'0'& ADMP & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & ARD_O; -- MP->MEM; A->MEM; EI

      -- ADC $xxxx,Y (absolute indexed)
      when  AYADC_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AYADC_OP1 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & YRD_O; -- MEM->MP_MSB; MEM->O+Y->MP_LSB; PC+1;
      when  AYADC_OP2 => q <= EXT_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; A=A+EXT; MP_MSB+CARRY, EI
      when  AYADC_OP3 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLV_P & SUM_A & ALD_R & ARD_O; -- MP->MEM; A=A+EXT
      when  AYADC_OP4 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAA_A & ALD_R & ARD_O; -- A=A+BCD ADJ (DAA); PC +1; EI

      -- SBC $xxxx,Y (absolute indexed)
      when  AYSBC_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AYSBC_OP1 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & YRD_O; -- MEM->MP_MSB; MEM->O+Y->MP_LSB; PC+1;
      when  AYSBC_OP2 => q <= EXT_D &'1'&'0'&'0'&'0'& RDE &'0'& ADMP & NOP_PC & ICC_M & NOP_P & NOP_A & NOP_R & EXT_O; -- MP->MEM; A=A-EXT; MP_MSB+CARRY, EI
      when  AYSBC_OP3 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLV_P & SUB_A & ALD_R & ARD_O; -- MP->MEM; A=A-EXT
      when  AYSBC_OP4 => q <= BCD_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & FLV_P & DAS_A & ALD_R & ARD_O; -- A=A-BCD ADJ (DAS); PC +1; EI

      -- CMP $xxxx,Y (absolute indexed)
      when  AYCMP_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AYCMP_OP1 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & YRD_O; -- MEM->MP_MSB; MEM->O+Y->MP_LSB; PC+1;
      when  AYCMP_OP2 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & ICC_M & FLC_P & CMP_A & NOP_R & ARD_O; -- MP->MEM; A-MEM MP_MSB+CARRY, EI
      when  AYCMP_OP3 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLC_P & CMP_A & NOP_R & ARD_O; -- MP->MEM; A-MEM; EI

      -- AND $xxxx,Y (absolute indexed)
      when  AYAND_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AYAND_OP1 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & YRD_O; -- MEM->MP_MSB; MEM->O+Y->MP_LSB; PC+1;
      when  AYAND_OP2 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & ICC_M & FLD_P & AND_A & ALD_R & ARD_O; -- MP->MEM; EXT AND A; MP_MSB+CARRY, EI
      when  AYAND_OP3 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & AND_A & ALD_R & ARD_O; -- MP->MEM; EXT AND A; EI

      -- ORA $xxxx,Y (absolute indexed)
      when  AYORA_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AYORA_OP1 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & YRD_O; -- MEM->MP_MSB; MEM->O+Y->MP_LSB; PC+1;
      when  AYORA_OP2 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & ICC_M & FLD_P &  OR_A & ALD_R & ARD_O; -- MP->MEM; EXT OR A; MP_MSB+CARRY, EI
      when  AYORA_OP3 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P &  OR_A & ALD_R & ARD_O; -- MP->MEM; EXT OR A; EI

      -- EOR $xxxx,Y (absolute indexed)
      when  AYEOR_OP0 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC+1
      when  AYEOR_OP1 => q <= ORD_D &'1'&'0'&'0'&'0'& RDE &'0'& ADPC & INC_PC & ALL_M & AUC_P & SWC_A & NOP_R & YRD_O; -- MEM->MP_MSB; MEM->O+Y->MP_LSB; PC+1;
      when  AYEOR_OP2 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & ICC_M & FLD_P & XOR_A & ALD_R & ARD_O; -- MP->MEM; EXT XOR A; MP_MSB+CARRY, EI
      when  AYEOR_OP3 => q <= EXT_D &'1'&'0'&'0'&'1'& RDE &'0'& ADMP & NOP_PC & NOP_M & FLD_P & XOR_A & ALD_R & ARD_O; -- MP->MEM; EXT XOR A; EI

      ------------------------------------
      --            RELATIVE            --
      ------------------------------------
      -- BRA xx
      when    BRA_OP0 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC +1;
      when    BRA_OP1 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & LSB_PC & NOP_M & NOP_P & SWC_A & NOP_R & PLR_O; -- PCL+O->PCL;
      when    BRA_OP2 => q <= ORD_D &'0'&'0'&'1'&'1'& RDE &'0'& ADPC & ADJ_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- PCH ADJUSTMENT;

      -- BEQ xx
      when    BEQ_OP0 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC +1;
      when    BEQ_OP1 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & LSB_PC & NOP_M & NOP_P & SWC_A & NOP_R & PLR_O; -- PCL+O->PCL;
      when    BEQ_OP2 => q <= ORD_D &'0'&'0'&'1'&'1'& RDE &'0'& ADPC & ADJ_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- PCH ADJUSTMENT;

      -- BNE xx
      when    BNE_OP0 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC +1;
      when    BNE_OP1 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & LSB_PC & NOP_M & NOP_P & SWC_A & NOP_R & PLR_O; -- PCL+O->PCL;
      when    BNE_OP2 => q <= ORD_D &'0'&'0'&'1'&'1'& RDE &'0'& ADPC & ADJ_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- PCH ADJUSTMENT;

      -- BCC xx
      when    BCC_OP0 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC +1;
      when    BCC_OP1 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & LSB_PC & NOP_M & NOP_P & SWC_A & NOP_R & PLR_O; -- PCL+O->PCL;
      when    BCC_OP2 => q <= ORD_D &'0'&'0'&'1'&'1'& RDE &'0'& ADPC & ADJ_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- PCH ADJUSTMENT;

      -- BCS xx
      when    BCS_OP0 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC +1;
      when    BCS_OP1 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & LSB_PC & NOP_M & NOP_P & SWC_A & NOP_R & PLR_O; -- PCL+O->PCL;
      when    BCS_OP2 => q <= ORD_D &'0'&'0'&'1'&'1'& RDE &'0'& ADPC & ADJ_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- PCH ADJUSTMENT;

      -- BVC xx
      when    BVC_OP0 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC +1;
      when    BVC_OP1 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & LSB_PC & NOP_M & NOP_P & SWC_A & NOP_R & PLR_O; -- PCL+O->PCL;
      when    BVC_OP2 => q <= ORD_D &'0'&'0'&'1'&'1'& RDE &'0'& ADPC & ADJ_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- PCH ADJUSTMENT;

      -- BVS xx
      when    BVS_OP0 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC +1;
      when    BVS_OP1 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & LSB_PC & NOP_M & NOP_P & SWC_A & NOP_R & PLR_O; -- PCL+O->PCL;
      when    BVS_OP2 => q <= ORD_D &'0'&'0'&'1'&'1'& RDE &'0'& ADPC & ADJ_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- PCH ADJUSTMENT;

      -- BPL xx
      when    BPL_OP0 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC +1;
      when    BPL_OP1 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & LSB_PC & NOP_M & NOP_P & SWC_A & NOP_R & PLR_O; -- PCL+O->PCL;
      when    BPL_OP2 => q <= ORD_D &'0'&'0'&'1'&'1'& RDE &'0'& ADPC & ADJ_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- PCH ADJUSTMENT;

      -- BMI xx
      when    BMI_OP0 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & INC_PC & NOP_M & NOP_P & NOP_A & OLD_R & EXT_O; -- MEM->O; PC +1;
      when    BMI_OP1 => q <= ORD_D &'0'&'0'&'1'&'0'& RDE &'0'& ADPC & LSB_PC & NOP_M & NOP_P & SWC_A & NOP_R & PLR_O; -- PCL+O->PCL;
      when    BMI_OP2 => q <= ORD_D &'0'&'0'&'1'&'1'& RDE &'0'& ADPC & ADJ_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- PCH ADJUSTMENT;

      when    others  => q <= NOP_D &'0'&'0'&'0'&'1'& RDE &'0'& ADPC & NOP_PC & NOP_M & NOP_P & NOP_A & NOP_R & EXT_O; -- EI
    end case;
  end process;
end comb;



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

entity envelope_generator is
   generic (
      G_CLOCK_HZ : integer
   );
   port (
      clk_i        : in  std_logic;
      rst_i        : in  std_logic;
      device_cnt_i : in  integer range 0 to 31;
      devices_i    : in  t_device_vector(0 to 31);
      envelopes_o  : out t_envelope_vector(0 to 31)
   );
end envelope_generator;

architecture synthesis of envelope_generator is

   constant C_ENVELOPE_MAX : t_envelope := (others => '1');

   type t_state is (ATTACK_ST, DECAY1_ST, DECAY2_ST, RELEASE_ST);

   type t_state_vector is array (natural range<>) of t_state;

   signal state_r : t_state_vector(0 to 31);

   signal device_s    : t_device;
   signal envelopes_r : t_envelope_vector(0 to 31);

begin

   -- Demultiplex input
   device_s <= devices_i(device_cnt_i);

   p_fsm : process (clk_i)
   begin
      if rising_edge(clk_i) then
         case state_r(device_cnt_i) is
            when ATTACK_ST =>
               envelopes_r(device_cnt_i) <= envelopes_r(device_cnt_i) + device_s.eg.attack_rate;

               if envelopes_r(device_cnt_i) >= C_ENVELOPE_MAX then
                  state_r(device_cnt_i) <= DECAY1_ST;
               end if;
               if device_s.eg.key_onoff = '0' then
                  state_r(device_cnt_i) <= RELEASE_ST;
               end if;

            when DECAY1_ST =>
               envelopes_r(device_cnt_i) <= envelopes_r(device_cnt_i) - device_s.eg.first_decay_rate;
               if envelopes_r(device_cnt_i) <= device_s.eg.first_decay_level then
                  state_r(device_cnt_i) <= DECAY2_ST;
               end if;
               if device_s.eg.key_onoff = '0' then
                  state_r(device_cnt_i) <= RELEASE_ST;
               end if;

            when DECAY2_ST =>
               envelopes_r(device_cnt_i) <= envelopes_r(device_cnt_i) - device_s.eg.second_decay_rate;
               if device_s.eg.key_onoff = '0' then
                  state_r(device_cnt_i) <= RELEASE_ST;
               end if;

            when RELEASE_ST =>
               envelopes_r(device_cnt_i) <= envelopes_r(device_cnt_i) - device_s.eg.release_rate;
               if device_s.eg.key_onoff = '1' then
                  state_r(device_cnt_i) <= ATTACK_ST;
               end if;

         end case;

         if rst_i = '1' then
            state_r     <= (others => RELEASE_ST);
            envelopes_r <= (others => (others => '0'));
         end if;
      end if;
   end process p_fsm;


   -- Connect output
   envelopes_o <= envelopes_r;

end architecture synthesis;


#![feature(lang_items)]
#![feature(global_asm)]
#![no_main]
#![no_std]

#[cfg(target_arch = "x86_64")]
global_asm!(include_str!("stage1.s"));
#[cfg(target_arch = "x86_64")]
global_asm!(include_str!("stage2.s"));

#[cfg(target_arch = "arm")]
global_asm!(include_str!("stage1arm.s"));

#[panic_handler]
#[no_mangle]
extern "C" fn panic_handler(_panic_info: &core::panic::PanicInfo) -> ! {
    loop {}
}

#[lang = "eh_personality"]
#[no_mangle]
pub extern "C" fn eh_personality() {
    loop {}
}

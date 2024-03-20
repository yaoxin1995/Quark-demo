fn main() {

    let args: Vec<String> = env::args().collect();
    let foo = match env::var("FOO") {
        Ok(val) => val,
        Err(_e) => "none".to_string(),
    };
    println!("Hello, world! len {}", NUMBERS.len());
    println!("cmd args {:?}, env  FOO {:?}", args, foo);
    

    let mut buf: Vec<u8> = vec![0; 500];
    let path = Path::new("/secret/root-ca.pem");
    let display = path.display();
    let file = match File::options()
        .read(true).open(path){
        Err(why) => panic!("couldn't open {}: {}", display, why),
        Ok(file) => file,
    };
    let fd = file.as_raw_fd();    
    let res = unsafe { syscall!(Sysno::read, fd, buf.as_mut_ptr() as *const _, 500) };
    if res.is_err() {
        println!("read systen call got error {:?}", res);
    } else {
        let s = String::from_utf8_lossy(&buf);
        println!("read systen call got data from root-ca {:?}", s);
    }

    
    let res = unsafe { syscall !(Sysno::pause) };
    if res.is_err() {
        println!("main pause got error {:?}", res);
    }
}
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/select.h>
#include <fcntl.h>
#include <errno.h>
#include <termios.h>
#include <pthread.h>
#include <semaphore.h>
#include <math.h>
/*头文件引入*/

#define UART_RX "/dev/ttyS1" // Receive UART1
#define UART_RX2 "/dev/ttyS2" // Receive UART2
#define UART_TX "/dev/ttyS3" // Transmit UART
//#define DATA_COUNT 400
#define BUFFER_SIZE 400 //DATA_COUNT
char ch1_head[] = {0x61,0x64,0x64,0x74,0x20,0x73,0x30,0x2E,0x69,0x64,0x2C,0x30,0x2C,0x34,0x30,0x30,0xff,0xff,0xff};
char ch2_head[] = {0x61,0x64,0x64,0x74,0x20,0x73,0x30,0x2E,0x69,0x64,0x2C,0x31,0x2C,0x34,0x30,0x30,0xff,0xff,0xff};
char gpio_direction[64];
char gpio_value[64];
int serial_open(const char *device, speed_t baudrate);
void serial_close(int fd);
ssize_t serial_write(int fd, const void *buf, size_t count);
int write_gpio(const char *file,const char *value);
int read_gpio(const char *file,char *value,int nbytes);
void gpio_init(const char *gpio);
void gpio_delete(const char *gpio);
void gpio_write_value(int gpio_pin,const char *value);
void gpio_read_value(int gpio_pin,const char *value);
void data_process(int *data_int,int y,double vpp,double vrms);
int main() {
    int rx_fd, tx_fd;
    char value[2] = {1};
    unsigned char rx1_buffer[BUFFER_SIZE];
    int data1_int[BUFFER_SIZE];
    ssize_t bytes_read, bytes_written;
    unsigned char rx2_buffer[BUFFER_SIZE];
    int data2_int[BUFFER_SIZE];
    int stop = 0,single = 0,load = 0,save = 0;
    int y1,y2;
    char *x_div,*y1_div,*y2_div;
    char *txt_send_buf;
    int x_0x,y1_0x,y2_0x;
    int ad1,ad2,tig;
    double vpp1,vrms1,vpp2,vrms2;
    // init gpio_pin
    gpio_init("40");//all_set
    gpio_init("38");//chi_receive


    gpio_init("63");
    gpio_init("62");   
    gpio_init("61");
    gpio_init("60");//x
    
    gpio_init("59");
    gpio_init("58");   
    gpio_init("57");
    gpio_init("56");//y1

    gpio_init("55");
    gpio_init("54");   
    gpio_init("53");
    gpio_init("52"); //y2

    gpio_init("51");//ad1
    gpio_init("50");//ad2
    gpio_init("49");//tig

    gpio_init("48");//single
    gpio_init("47");//stop
    gpio_init("46");//save
    gpio_init("45");//load
    //初始化时赋高电平作为开始工作标志位。
    gpio_write_value(40,"1"); 
    x_0x = (gpio_read_value(60) << 3 )|(gpio_read_value(61) << 2)|(gpio_read_value(62) << 1)|(gpio_read_value(63));
    y1_0x = (gpio_read_value(56) << 3 )|(gpio_read_value(57) << 2)|(gpio_read_value(58) << 1)|(gpio_read_value(59));
    y2_0x = (gpio_read_value(52) << 3 )|(gpio_read_value(53) << 2)|(gpio_read_value(54) << 1)|(gpio_read_value(55));
    ad1 = gpio_read_value(51);
    ad2 = gpio_read_value(50);
    tig = gpio_read_value(49);
    single = gpio_read_value(48);
    stop = gpio_read_value(47);
    save = gpio_read_value(46);
    load = gpio_read_value(45);
    if(ad1){
        sprintf(txt_send_buf,"t0.txt=\"AC\"");
        serial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
    }
    else{
        sprintf(txt_send_buf,"t0.txt=\"DC\"");
        serial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
    }
    if(ad2){
        sprintf(txt_send_buf,"t4.txt=\"AC\"");
        serial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
    }
    else{
        sprintf(txt_send_buf,"t4.txt=\"DC\"");
        serial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
    }
    if(tig){
        sprintf(txt_send_buf,"t7.txt=\"UP\"");
        serial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
    }
    else{
        sprintf(txt_send_buf,"t7.txt=\"DOWN\"");
        serial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
    }
    switch(x_0x)
    {
        case 0:x_div ="100ns/div";break;
        case 1:x_div = "200ns/div";break;
        case 2:x_div = "2us/div";break;
        case 3:x_div = "10us/div";break;
        case 4:x_div = "25us/div";break;
        case 5:x_div = "50us/div";break;
        case 6:x_div = "100us/div";break;
        case 7:x_div = "250us/div";break;
        case 8:x_div = "500us/div";break;
        case 9:x_div = "1ms/div";break;
        case 10:x_div = "2.5ms/div";break;
        case 11:x_div = "5ms/div";break;
        case 12:x_div = "10ms/div";break;
        case 13:x_div = "25ms/div";break;
        case 14:x_div = "50ms/div";break;
        case 15:x_div = "100ms/div";break;
    }
    sprintf(txt_send_buf,"t3.txt=\"%s\"%x%x%x",x_div,0xff,0xff,0xff);
    serial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
    switch(y1_0x)
    {
        case 0:y1_div ="1mV/div";y1 =1;break;
        case 1:y1_div = "2mV/div";y1 =2;break;
        case 2:y1_div = "4mV/div";y1 = 4;break;
        case 3:y1_div = "5mV/div";y1 = 5;break;
        case 4:y1_div = "10mV/div";y1 = 10;break;
        case 5:y1_div = "20mV/div";y1 = 20;break;
        case 6:y1_div = "40mV/div";y1 = 40;break;
        case 7:y1_div = "50mV/div";y1 = 50;break;
        case 8:y1_div = "80mV/div";y1 = 80;break;
        case 9:y1_div = "100mV/div";y1 = 100;break;
        case 10:y1_div = "200mV/div";y1 = 200;break;
        case 11:y1_div = "400mV/div";y1 = 400;break;
        case 12:y1_div = "0.5V/div";y1 = 500;break;
        case 13:y1_div = "0.8V/div";y1 = 800;break;
        case 14:y1_div = "1V/div";y1 = 1000;break;
        case 15:y1_div = "1.2V/div";y1 = 1200;break;
    }
    sprintf(txt_send_buf,"t9.txt=\"ch1:%s\"%x%x%x",y1_div,0xff,0xff,0xff);
    serial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
    switch(y2_0x)
    {
        case 0:y2_div ="1mV/div";y2 = 1;break;
        case 1:y2_div = "2mV/div";y2 = 2;break;
        case 2:y2_div = "4mV/div";y2 = 4;break;
        case 3:y2_div = "5mV/div";y2 = 5;break;
        case 4:y2_div = "10mV/div";y2 = 10;break;
        case 5:y2_div = "20mV/div";y2 = 20;break;
        case 6:y2_div = "40mV/div";y2 = 40;break;
        case 7:y2_div = "50mV/div";y2 = 50;break;
        case 8:y2_div = "80mV/div";y2 = 80;break;
        case 9:y2_div = "100mV/div";y2 = 100;break;
        case 10:y2_div = "200mV/div";y2 = 200;break;
        case 11:y2_div = "400mV/div";y2 = 400;break;
        case 12:y2_div = "0.5V/div";y2 = 500;break;
        case 13:y2_div = "0.8V/div";y2 = 800;break;
        case 14:y2_div = "1V/div";y2 = 000;break;
        case 15:y2_div = "1.2V/div";y2 = 1200;break;
    }
    sprintf(txt_send_buf,"t8.txt=\"ch2:%s\"%x%x%x",y2_div,0xff,0xff,0xff);
    serial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
    // Open and configure the receive UART1
    rx_fd = serial_open(UART_RX, B115200);
    if (rx_fd == -1) {
        return EXIT_FAILURE;
    }

    // Open and configure the transmit UART
    tx_fd = serial_open(UART_TX, B115200);
    if (tx_fd == -1) {
        serial_close(rx_fd);
        return EXIT_FAILURE;
    }

    // Set UART to blocking mode and other configurations
    struct termios options;
    tcgetattr(rx_fd, &options);
    options.c_cc[VMIN] = 1; // Wait for at least DATA_COUNT bytes
    options.c_cc[VTIME] = 0;         // Infinite timeout
    tcsetattr(rx_fd, TCSANOW, &options);


    // Read exactly DATA_COUNT bytes from the UART1
    ssize_t bufferSize = BUFFER_SIZE;
    unsigned char *rxBuffer = rx1_buffer;
    int bytes_read_all = 0;    
    gpio_write_value(38,"1"); 
    while(bufferSize != 0 ){
    bytes_read = read(rx_fd, rxBuffer, bufferSize);
        bytes_read_all +=bytes_read;
        bufferSize -= bytes_read;
        rxBuffer += bytes_read;
    }if (bytes_read_all != BUFFER_SIZE) {
        perror("Error reading from UART:\n");
        printf("\n%d\n",bytes_read);
        serial_close(rx_fd);
        serial_close(tx_fd);
        return EXIT_FAILURE;
    }
  
    // Read exactly DATA_COUNT bytes from the UART2
    bufferSize = BUFFER_SIZE;
    rxBuffer = rx2_buffer;
    bytes_read_all = 0;    
 
    while(bufferSize != 0 ){
    bytes_read = read(rx_fd, rxBuffer, bufferSize);
        bytes_read_all +=bytes_read;
        bufferSize -= bytes_read;
        rxBuffer += bytes_read;
    }if (bytes_read_all != BUFFER_SIZE) {
        perror("Error reading from UART:\n");
        printf("\n%d\n",bytes_read);
        serial_close(rx_fd);
        serial_close(tx_fd);
        return EXIT_FAILURE;
    }
    gpio_write_value(38,"0"); 
    // Convert the received data to integers in the range 0-255
    for (int i = 0; i < 400; i++) {
        data1_int[i] = (int)rx1_buffer[i] & 0xFF; // Mask to fit in 0-255 range
    }

    // Convert the received data to integers in the range 0-255
    for (int i = 0; i < 400; i++) {
        data2_int[i] = (int)rx2_buffer[i] & 0xFF; // Mask to fit in 0-255 range
    }
    data_process(data1_int,y1,vpp1,vrms1);
    data_process(data2_int,y2,vpp2,vrms2);
    if(vpp1 >=1000){
        sprintf(txt_send_buf,"t1.txt=\"Vpp1:%.2fV\"",vpp1/1000);
        erial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
        sprintf(txt_send_buf,"t2.txt=\"Vrms1:%.2fV\"",vrms1/1000);    
        erial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
    }
    else{
        sprintf(txt_send_buf,"t1.txt=\"Vpp1:%.2fmV\"",vpp1);
        erial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
        sprintf(txt_send_buf,"t2.txt=\"Vrms1:%.2fmV\"",vrms1);    
        erial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
    }
    if(vpp2 >=1000){
        sprintf(txt_send_buf,"t5.txt=\"Vpp1:%.2fV\"",vpp2/1000);
        erial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
        sprintf(txt_send_buf,"t6.txt=\"Vrms1:%.2fV\"",vrms2/1000);    
        erial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
    }
    else{
        sprintf(txt_send_buf,"t5.txt=\"Vpp1:%.2fmV\"",vpp2);
        erial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
        sprintf(txt_send_buf,"t6.txt=\"Vrms1:%.2fmV\"",vrms2);    
        erial_write(tx_fd,txt_send_buf,sizeof(txt_send_buf));
    }
    // Write the converted data to the transmit UART
    bytes_written = serial_write(tx_fd, ch1_head, sizeof(ch1_head));
    if (bytes_written < 0) {
        perror("Error writing to UART1");
        serial_close(rx_fd);
        serial_close(tx_fd);
        return EXIT_FAILURE;
    }

    bytes_written = serial_write(tx_fd, rx1_buffer, BUFFER_SIZE );
    if (bytes_written < 0) {
        perror("Error writing to UART1");
        serial_close(rx_fd);
        serial_close(tx_fd);
        return EXIT_FAILURE;
    }

    // Write the converted data to the transmit UART
    bytes_written = serial_write(tx_fd, ch2_head, sizeof(ch2_head));
    if (bytes_written < 0) {
        perror("Error writing to UART2");
        serial_close(rx_fd);
        serial_close(tx_fd);
        return EXIT_FAILURE;
    }

    bytes_written = serial_write(tx_fd, rx2_buffer, BUFFER_SIZE );
    if (bytes_written < 0) {
        perror("Error writing to UART2");
        serial_close(rx_fd);
        serial_close(tx_fd);
        return EXIT_FAILURE;
    }

    // Close the UART devices
    serial_close(rx_fd);
    serial_close(tx_fd);
    gpio_write_value(40,"0");
    gpio_delete("63");
    gpio_delete("62");
    gpio_delete("61");
    gpio_delete("60");
    gpio_delete("59");
    gpio_delete("58");
    gpio_delete("57");
    gpio_delete("56");
    gpio_delete("55");
    gpio_delete("54");
    gpio_delete("53");
    gpio_delete("52");
    gpio_delete("51");
    gpio_delete("50");
    gpio_delete("49");
    gpio_delete("48");
    gpio_delete("47");
    gpio_delete("46");
    gpio_delete("45");
    gpio_delete("38");
    gpio_delete("40");
    return EXIT_SUCCESS;

}

// Function to open and configure the serial port
int serial_open(const char *device, speed_t baudrate) {
    int fd = open(device, O_RDWR | O_NOCTTY | O_NDELAY);
    if (fd == -1) {
        perror("Error opening serial port");
        return -1;
    }

    // Change to blocking mode
    fcntl(fd, F_SETFL, 0);

    // Configure serial port
    struct termios tty;
    memset(&tty, 0, sizeof(tty));
    if (tcgetattr(fd, &tty) != 0) {
        perror("Error from tcgetattr");
        return -1;
    }

    cfsetospeed(&tty, baudrate);
    cfsetispeed(&tty, baudrate);

    tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;     // 8-bit chars
    // disable IGNBRK for mismatched speed tests; otherwise receive break
    // as \000 chars
    tty.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
    tty.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
    tty.c_oflag &= ~OPOST;

    if (tcsetattr(fd, TCSANOW, &tty) != 0) {
        perror("Error from tcsetattr");
        return -1;
    }

    return fd;
}

// Function to close the serial port
void serial_close(int fd) {
    close(fd);
}

// Function to write data to the serial port
ssize_t serial_write(int fd, const void *buf, size_t count) {
    return write(fd, buf, count);
}
int write_gpio(const char *file,const char *value){
    int fd,len;
    fd = open(file,O_WRONLY);
    if(fd<0){
        return -1;
    }
    len = write(fd,value,strlen(value));
    if(len != strlen(value)){
        return -2;
    }
    if(fsync(fd) == -1){
        perror("error syncing file tu disk");
        close(fd);
        return 1;
    }
  //  printf("%d\t%d\n",len,fd);
    close(fd);
}
int read_gpio(const char *file,char *value,int nbytes){
    int fd,len;
    fd = open(file,O_RDONLY);
    if(fd <0){
        return -1;
    }
    len = read(fd,value,nbytes);
    if(len != nbytes){
        printf("%d\t%d\n",len,fd);
        return -2;
    }
    close(fd);
}
void gpio_init(const char *gpio){
    int fd;
    fd=write_gpio("/sys/class/gpio/export",gpio);
    if(fd<0){
        printf("gpio%s init failed\n",gpio);
    }
}
void gpio_delete(const char *gpio){
    int fd;
    fd=write_gpio("/sys/class/gpio/unexport",gpio);
    if(fd<0){
        printf("gpio%s delete failed\n",gpio);
    }
}
void gpio_write_value(int gpio_pin,const char *value){
    sprintf(gpio_direction,"/sys/class/gpio/gpio%d/direction",gpio_pin);
    sprintf(gpio_value,"/sys/class/gpio/gpio%d/value",gpio_pin);
    fd = write_gpio(gpio_direction,"out");
    if(fd<0){
        printf("gpio direction %d set failed\n",gpio_pin);
    }
     fd = write_gpio(gpio_value,value);
    if(fd<0){
        printf("gpio value %d write failed\n",gpio_pin);
    }

}
int gpio_read_value(int gpio_pin){
    const char *value ; 
     sprintf(gpio_direction,"/sys/class/gpio/gpio%d/direction",gpio_pin);
    sprintf(gpio_value,"/sys/class/gpio/gpio%d/value",gpio_pin);
    fd = write_gpio(gpio_direction,"in");
    if(fd<0){
        printf("gpio direction %d set failed\n",gpio_pin);
    }
     fd = read_gpio(gpio_value,value,1);
    if(fd<0){
        printf("gpio value %d write failed\n",gpio_pin);
    }
    return (int)value;
}
void data_process(int *data_int,int y,double vpp,double vrms){
    double voltage[sizeof(data_int)/sizeof(int)];
    int t,i;
    double j,add = 0;
    for(t =0;t<sizeof(data_int)/size(int);t++){
        voltage[t] = ((double)data_int[t]*y)/32;
    }
    for(t =0;t<sizeof(data_int)/size(int);t++){
        for(i =i;i<sizeof(data_int)/size(int);i++){
            if(voltage(t)<voltage[i]){
                j = voltage[t];
                voltage[t] = voltage[i];
                voltage[i] = j;
            }
        }
    }
    vpp = voltage[0] = voltage[t=1];
    for(t =0;t<sizeof(data_int)/size(int);t++){
        add += voltage[t]*voltage*[t];
    }
    vrms = sqrt(add/400);
}
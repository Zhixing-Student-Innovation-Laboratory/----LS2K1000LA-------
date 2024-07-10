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
/*头文件引入*/
#define BAUDRATE B115200
#define BUFFER_SIZE 400
#define NUM_BUFFERS 10 // 每个UART读取的缓冲区数量
#define GPIO_COUNT 22
#define GPIO_COUNT_IN 19
#define DEV_Receive1  "/dev/ttyS1"
#define DEV_Receive2  "/dev/ttyS2"
#define DEV_Translate1  "/dev/ttyS3"
/*变量宏定义*/
int gpio_pin[] = {41,42,43,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62};
int stop,load,save,single,ad1,ad2,tig;
int data_save[400];
int data_load[400];
int key_single_click[] = {0,0,0,0,0,0,0}
ad1 = 0;ad2 = 0;tig = 0;stop = 0;load = 0;save = 0; single = 0;
//int mode_stop = 0;
int vpp1,vpp2,vrms1,vrms2;
/*全局变量定义*/
struct uart_config {
    const char *port; // UART设备文件
    char **buffers; // 缓冲区数组
    int tx_fd; // 发送数据的UART设备文件描述符
    
};
typedef struct {
    unsigned int voltage_code1 : 4;
    unsigned int voltage_code2 : 4;
    unsigned int time_code : 4;
    unsigned int reserved : 3;
} GpioCodes;

struct gpio_config {
    int *gpio_fds; // GPIO设备文件描述符数组
    int tx_fd;     // 发送数据的UART设备文件描述符
};

struct termios tty;
sem_t send_lock; // 用于发送操作的互斥锁
/*结构体定义*/
// 配置串口参数
void configure_uart(int fd) {
    memset(&tty, 0, sizeof(tty));
    cfsetospeed(&tty, BAUDRATE);
    cfsetispeed(&tty, BAUDRATE);
    tty.c_cflag &= ~PARENB; // 无奇偶校验位
    tty.c_cflag &= ~CSTOPB; // 1个停止位
    tty.c_cflag &= ~CSIZE;
    tty.c_cflag |= CS8; // 8数据位
    tty.c_cflag &= ~CRTSCTS; // 无硬件流控
    tty.c_cc[VMIN] = 1; // 至少读取1字节
    tty.c_cc[VTIME] = 5; // 等待最多0.5秒
    tcflush(fd, TCIFLUSH);
    tcsetattr(fd, TCSANOW, &tty);
}
// 数据处理函数
void process_data(char *buffer, ssize_t bytes_read) {
    // 在这里添加数据处理逻辑
    // 例如，你可以计算数据的平均值、最大值或最小值，或者执行其他复杂的算法
    // 下面是一个简单的示例，打印接收到的原始数据
    printf("接收到的数据：");
    for (ssize_t i = 0; i < bytes_read; ++i) {
        printf("%02X ", (unsigned char)buffer[i]);
    }
    printf("\n");
}
//电压换算函数
double decode_voltage(unsigned int x){
    double result;
    switch(x){
        case 0:result = 0;break;
        case 1:result = 0;break;
        case 2:result = 0;break;
        case 3:result = 0;break;
        case 4:result = 0;break;
        case 5:result = 0;break;
        case 6:result = 0;break;
        case 7:result = 0;break;
        case 8:result = 0;break;
        case 9:result = 0;break;
        case 10:result = 0;break;
        case 11:result = 0;break;
        case 12:result = 0;break;
        case 13:result = 0;break;
        case 14:result = 0;break;
        case 15:result = 0;break;
    }
    return result;
}
//时间换算函数
double decode_time(unsigned int x){
    double result;
    switch(x){
        case 0:result = 0;break;
        case 1:result = 0;break;
        case 2:result = 0;break;
        case 3:result = 0;break;
        case 4:result = 0;break;
        case 5:result = 0;break;
        case 6:result = 0;break;
        case 7:result = 0;break;
        case 8:result = 0;break;
        case 9:result = 0;break;
        case 10:result = 0;break;
        case 11:result = 0;break;
        case 12:result = 0;break;
        case 13:result = 0;break;
        case 14:result = 0;break;
        case 15:result = 0;break;
    }
    return result;
}
//导出gpio函数
void export_gpio(int gpio) {
    int fd;
    char buf[32];

    // 打开/export文件
    fd = open("/sys/class/gpio/export", O_WRONLY);
    if (fd < 0) {
        perror("打开/export文件失败");
        exit(-1);
    }

    // 写入GPIO编号
    snprintf(buf, sizeof(buf), "%d", gpio);
    write(fd, buf, strlen(buf) + 1);
    close(fd);
}
//设置gpio模式函数
void set_gpio_direction(int gpio, const char *direction) {
    int fd;
    char path[32];
    char buf[32];

    // 构建方向文件路径
    snprintf(path, sizeof(path), "/sys/class/gpio/gpio%d/direction", gpio);

    // 打开方向文件
    fd = open(path, O_WRONLY);
    if (fd < 0) {
        perror("打开方向文件失败");
        exit(-1);
    }

    // 写入方向
    write(fd, direction, strlen(direction) + 1);
    close(fd);
}
//改变输出gpio电平状态函数
void set_gpio_output_level(int gpio, int level) {
    int value_fd;
    char value_path[32];
    char level_str[3];

    // 构建GPIO value文件路径
    snprintf(value_path, sizeof(value_path), "/sys/class/gpio/gpio%d/value", gpio);

    // 打开GPIO value文件
    value_fd = open(value_path, O_WRONLY);
    if (value_fd < 0) {
        perror("打开GPIO value文件失败");
        exit(-1);
    }

    // 设置电平，1为高电平，0为低电平
    if (level) {
        strcpy(level_str, "1");
    } else {
        strcpy(level_str, "0");
    }
}
//第13脚gpio按下
void handle_gpio_12(int value){
    //coupling1
    if(value&!key_single_click[0])
    (
        ad1 = !ad1;
        key_single_click[0] = 1;
        break;
    )
    else if(!value)
    {
        key_single_click[0] = 0
        break;
    }
    
}
//第14脚gpio按下
void handle_gpio_13(int value){
    //coupling2
    if(value&!key_single_click[1])
    (
        ad2 = !ad2;
        key_single_click[1] = 1;
        break;
    )
    else if(!value)
    {
        key_single_click[1] = 0
        break;
    }
    
}
//第15脚gpio按下
void handle_gpio_14(int value){
    //tig
    if(value&!key_single_click[2])
    (
        tig = !tig;
        key_single_click[2] = 1;
        break;
    )
    else if(!value)
    {
        key_single_click[2] = 0
        break;
    }
}
//第16脚gpio按下
void handle_gpio_15(int value){
    //stop
    if(value&!key_single_click[3])
    {
        stop = !stop;
        key_single_click[3] = 1;
        break;
}
    else if(!value)
    {
        key_single_click[3] = 0;
        break;
    }
}
//第17脚gpio按下
void handle_gpio_16(int value){
    //save
    if(value&!key_single_click[4])
    (
        memcpy(data_load,data_save,strlen(data_save)+1);
        key_single_click[4] = 1;
        break;
    )
    else if(!value)
    {
        key_single_click[4] = 0
        break;
    }
}
//第18脚gpio按下
void handle_gpio_17(int value){
    //load
    if(value&!key_single_click[4])
    (
        stop = 1;
        key_single_click[5] = 1;
        break;
    )
    else if(!value)
    {
        key_single_click[5] = 0
        break;
    }
}
//第19脚gpio按下
void handle_gpio_18(int value){
    //single
    if(value&!key_single_click[6])
    (
        stop = 1;
        key_single_click[6] = 1;
        break;
    )
    else if(!value)
    {
        key_single_click[6] = 0
        break;
    }
}

/*函数定义*/
// UART读取线程
void *read_uart_data(void *arg) {
    struct uart_config *config = (struct uart_config *)arg;
    int fd = open(config->port, O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (fd < 0) {
        perror("打开串口失败");
        return NULL;
    }

    configure_uart(fd); // 配置串口

    ssize_t bytes_read;
    int i;

   // 定义select所需的fd_set结构体
    fd_set readfds;
    FD_ZERO(&readfds);
    FD_SET(fd, &readfds);

    for (i = 0; i < NUM_BUFFERS; i++) {
        // 使用select等待数据就绪
        int ret = select(fd + 1, &readfds, NULL, NULL, NULL);
        if (ret < 0) {
            perror("select()失败");
            break;
        } else if (ret == 0) {
            // select()返回0表示超时，但这里我们没有设置超时时间，所以这种情况不会发生
            // 可能是某些异常情况，处理或忽略
        } else {
            // 有数据可读，进行读取操作
            bytes_read = read(fd, config->buffers[i], BUFFER_SIZE);
            if (bytes_read < 0) {
                perror("从串口读取数据失败");
                break;
            }
        }
    }
    // 确保所有数据读取完毕后，才进行数据处理和发送
    if (i == NUM_BUFFERS) {
        // 将所有缓冲区的数据拼接到一起
        char *all_data = malloc(BUFFER_SIZE * NUM_BUFFERS);
        memset(all_data, 0, BUFFER_SIZE * NUM_BUFFERS);
        for (int j = 0; j < NUM_BUFFERS; j++) {
            memcpy(all_data + (BUFFER_SIZE * j), config->buffers[j], BUFFER_SIZE);
        }

        // 数据处理
        process_data(all_data, BUFFER_SIZE * NUM_BUFFERS);

        // 将处理后的数据写入第三个串口
        sem_wait(&send_lock);
        memcpy(data_load,all_data,strlen(all_data)+1);
        ssize_t bytes_written = write(config->tx_fd, all_data, BUFFER_SIZE * NUM_BUFFERS);
        if (bytes_written != BUFFER_SIZE * NUM_BUFFERS) {
            perror("写入串口数据失败");
        }
        sem_post(&send_lock);

        free(all_data);
    }


    close(fd); // 关闭读取串口
    return NULL;
}
// GPIO读取线程
void *read_gpio_states(void *arg) {
    struct gpio_config *config = (struct gpio_config *)arg;
    GpioCodes gpio_codes;
    double voltage1, voltage2, times;

    while (1) {
        // 读取GPIO状态
        for (int i = 0; i < 19; ++i) {
            int pin = gpio_pin[i]; // 从数组中获取当前GPIO引脚号

            char value_str[3];
            read(config->gpio_fds[i], value_str, 2);
            value_str[2] = '\0';
            int value = atoi(value_str);

            switch (i) {
                case 0: gpio_codes.voltage_code1 = (value << 3); break;
                case 1: gpio_codes.voltage_code1 |= (value << 2); break;
                case 2: gpio_codes.voltage_code1 |= (value << 1); break;
                case 3: gpio_codes.voltage_code1 |= value; break;
                case 4: gpio_codes.voltage_code2 = (value << 3); break;
                case 5: gpio_codes.voltage_code2 |= (value << 2); break;
                case 6: gpio_codes.voltage_code2 |= (value << 1); break;
                case 7: gpio_codes.voltage_code2 |= value; break;
                case 8: gpio_codes.time_code = (value << 3); break;
                case 9: gpio_codes.time_code |= (value << 2); break;
                case 10: gpio_codes.time_code |= (value << 1); break;
                case 11: gpio_codes.time_code |= value; break;
                // 新增对额外GPIO口的处理
                case 12: handle_gpio_12(value); break;
                case 13: handle_gpio_13(value); break;
                case 14: handle_gpio_14(value); break;
                case 15: handle_gpio_15(value); break;
                case 16: handle_gpio_16(value); break;
                case 17: handle_gpio_17(value); break;
                case 18: handle_gpio_18(value); break;

                default:
                    break;
            }
        }

        // 根据GPIO状态计算电压和时间值
        voltage1 = decode_voltage(gpio_codes.voltage_code1);
        voltage2 = decode_voltage(gpio_codes.voltage_code2);
        times = decode_time(gpio_codes.time_code);

        // 发送数据前获取锁
        sem_wait(&send_lock);
        
        // 发送电压和时间值
        char message[100];
        snprintf(message, sizeof(message), "voltage1 = %.2f, voltage2 = %.2f, times = %.2f\n", voltage1, voltage2, times);
        write(config->tx_fd, message, strlen(message));

        // 释放锁
        sem_post(&send_lock);
        
        // 等待一段时间后再读取
        usleep(100000); // 等待100ms
    }

    return NULL;
}
int main() {
    int i;
    pthread_t threads[2]; // 存储两个读取线程的句柄
    struct uart_config configs[2];
// 初始化GPIO配置
struct gpio_config gpio_config;
gpio_config.gpio_fds = (int *)malloc(GPIO_COUNT * sizeof(int));
// 打开GPIO设备
for (int i = 0; i < GPIO_COUNT_IN; ++i) {
        export_gpio(gpio_pin[i]); // 导出GPIO引脚
        set_gpio_direction(gpio_pin[i], "in"); // 设置为输入模式
        char gpio_path[20];
        sprintf(gpio_path, "/sys/class/gpio/gpio%d/value", gpio_pin[i]);
        gpio_config.gpio_fds[i] = open(gpio_path, O_RDONLY);
        if (gpio_config.gpio_fds[i] < 0) {
            perror("打开GPIO设备失败");
            exit(-1);
        }
}
    export_gpio(60); // 导出GPIO60引脚
    set_gpio_direction(60, "out"); // 设置为输出模式
    set_gpio_output_level(60,1);//设置为高电平
    export_gpio(61); // 导出GPIO61引脚
    set_gpio_direction(61, "out"); // 设置为输出模式
    export_gpio(62); // 导出GPIO62引脚
    set_gpio_direction(62, "out"); // 设置为输出模式
// 打开用于发送数据的UART设备
gpio_config.tx_fd = open("/dev/ttyUSB2", O_WRONLY | O_NOCTTY);
if (gpio_config.tx_fd < 0) {
    perror("打开发送串口失败");
    exit(-1);
}
    // 创建GPIO读取线程
    pthread_t gpio_thread;
    if (pthread_create(&gpio_thread, NULL, read_gpio_states, &gpio_config)) {
        perror("创建GPIO读取线程失败");
        exit(-1);
    }
    // 初始化第一个UART配置
    configs[0].port = "/dev/ttyS1"; // 第一个UART设备
    configs[0].buffers = (char **)malloc(NUM_BUFFERS * sizeof(char *));
    for (i = 0; i < NUM_BUFFERS; i++) {
        configs[0].buffers[i] = (char*)malloc(BUFFER_SIZE);
    }
    // 初始化第二个UART配置
    configs[1].port = "/dev/ttyS2"; // 第二个UART设备
    configs[1].buffers = (char **)malloc(NUM_BUFFERS * sizeof(char *));
    for (i = 0; i < NUM_BUFFERS; i++) {
        configs[1].buffers[i] = (char*)malloc(BUFFER_SIZE);
    }
    // 打开用于发送数据的UART设备
    int tx_fd = open("/dev/ttyS3", O_WRONLY | O_NOCTTY);
    if (tx_fd < 0) {
        perror("打开发送串口失败");
        exit(-1);
    }
    // 设置发送数据的UART设备文件描述符
    configs[0].tx_fd = tx_fd;
    configs[1].tx_fd = tx_fd;
    // 创建两个读取线程，每个线程负责一个UART接口
    if (pthread_create(&threads[0], NULL, read_uart_data, &configs[0])) {
        perror("创建第一个读取线程失败");
        exit(-1);
    }
    if (pthread_create(&threads[1], NULL, read_uart_data, &configs[1])) {
        perror("创建第二个读取线程失败");
        exit(-1);
    }

    // 等待两个读取线程完成
    pthread_join(threads[0], NULL);
    pthread_join(threads[1], NULL);

    // 关闭用于发送数据的UART设备
    close(tx_fd);
    // 清理
    for (i = 0; i < 2; i++) {
        for (int j = 0; j < NUM_BUFFERS; j++) {
            free(configs[i].buffers[j]);
        }
        free(configs[i].buffers);
    }
    for (int i = 0; i < GPIO_COUNT; ++i) {
        close(gpio_config.gpio_fds[i]);
    }
    free(gpio_config.gpio_fds);

    return 0;
}
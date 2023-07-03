#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <string.h>
#include <sys/syscall.h>

#define PATH_LENGTH 128 
#define BUFFER_LENGTH 64
#define CGROUP_LENGTH 64

char k8s[] = "k8s.io";
char cpu[] = "cpu";
char cpuset[] = "cpuset";
char memory[] = "memory";

#define OPEN_ERROR -1
#define WRITE_ERROR -2
#define DESTROY_ERROR -3
#define CREATE_ERROR -4

int remove_cgroup(char *path)
{
	int status;
	status = rmdir(path);
	if (status)
		return DESTROY_ERROR;
}

int create_cgroup(char *buffer)
{
	int status;
	status = mkdir(buffer, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
	if (status)
		return CREATE_ERROR;
	return 0;

}

int write_subtree_control(char *path, char *subsys, int add)
{
	FILE *fd = fopen(path, "a");
	size_t cnt;
	if(NULL == fd)
		return OPEN_ERROR;
	char modify_subtree_control[BUFFER_LENGTH];
	if(add == 1)
		sprintf(modify_subtree_control, "+%s", subsys);
	else sprintf(modify_subtree_control, "-%s", subsys);
	printf("%s, len=%d\n", modify_subtree_control, strlen(modify_subtree_control));
	cnt = fwrite(modify_subtree_control, strlen(modify_subtree_control), 1, fd);
	fclose(fd);
	if(!cnt)
		return WRITE_ERROR;
	return 0;
}

int create_k8s()
{
	char k8s_path[PATH_LENGTH];
	char buffer[BUFFER_LENGTH];
	sprintf(k8s_path, "/sys/fs/cgroup/%s", k8s);
	if (create_cgroup(k8s_path))
		return CREATE_ERROR;
	
	sprintf(k8s_path, "/sys/fs/cgroup/%s/cgroup.subtree_control", k8s);
	write_subtree_control(k8s_path, cpu, 1);
	write_subtree_control(k8s_path, cpuset, 1);	
	write_subtree_control(k8s_path, memory, 1);
	return 0;
}

int remove_k8s()
{
	int i;
	char k8s_path[PATH_LENGTH];
	sprintf(k8s_path, "/sys/fs/cgroup/%s/cgroup.subtree_control", k8s);
	write_subtree_control(k8s_path, cpu, 0);
	write_subtree_control(k8s_path, cpuset, 0);
	write_subtree_control(k8s_path, memory, 0);	
	sprintf(k8s_path, "/sys/fs/cgroup/%s",  k8s);
	if (remove_cgroup(k8s_path))
		return DESTROY_ERROR;
	return 0;
}

int main(void){
    if(create_k8s() != 0){
	printf("create k8s error\n");
	exit(1);
    }	
    printf("k8s created!\n");
    getchar();
    if(remove_k8s() != 0){
	printf("remove k8s error\n");
	exit(1);
    }
    printf("k8s deleted!\n");
    return 0;
}

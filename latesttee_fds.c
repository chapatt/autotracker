#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

void cleanup(int *fds, size_t nfiles);

void main(int argc, char *argv[])
{
	int *fds = NULL;
	size_t nfiles = argc - 1;
	char buf[16];
	size_t bytes_read;

	if ((fds = malloc(nfiles * sizeof(*fds))) == NULL) {
		fprintf(stderr, "Could not allocate memory.\n");
		cleanup(fds, nfiles);
	}

	for (size_t i=0; i < nfiles; ++i) {
		char *filename = argv[i + 1];
		if ((fds[i] = open(filename, O_WRONLY)) == -1) {
			fprintf(stderr, "Could not open file for writing: `%s'\n", filename);
			cleanup(fds, nfiles);
		}
		fcntl(fds[i], F_SETPIPE_SZ, 2);
		fcntl(fds[i], F_SETFL, O_NONBLOCK);
	}

	while (bytes_read = fread(buf, sizeof(*buf), sizeof(buf), stdin)) {
		for (size_t i=0; i < nfiles; ++i) {
			write(fds[i], buf, bytes_read);
			fsync(fds[i]);
		}
	}

	cleanup(fds, nfiles);
}

void cleanup(int *fds, size_t nfiles) {
	for (size_t i=0; i < nfiles; ++i) {
		if (fds[i])
			close(fds[i]);
	}

	if (fds)
		free(fds);

	exit(EXIT_FAILURE);
}

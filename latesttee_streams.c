#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>

void cleanup(FILE **files, size_t nfiles);

void main(int argc, char *argv[])
{
	FILE **files = NULL;
	size_t nfiles = argc - 1;
	char buf[4096];
	size_t bytes_read;

	if ((files = malloc(nfiles * sizeof(*files))) == NULL) {
		fprintf(stderr, "Could not allocate memory.\n");
		cleanup(files, nfiles);
	}

	for (size_t i=0; i < nfiles; ++i) {
		char *filename = argv[i + 1];
		if ((files[i] = fopen(filename, "w")) == NULL) {
			fprintf(stderr, "Could not open file for writing: `%s'\n", filename);
			cleanup(files, nfiles);
		}
		fcntl(fileno(files[i]), F_SETPIPE_SZ, 2);
		fcntl(fileno(files[i]), F_SETFL, O_NONBLOCK);
	}

	while (bytes_read = fread(buf, sizeof(*buf), sizeof(buf), stdin)) {
		for (size_t i=0; i < nfiles; ++i) {
			fwrite(buf, bytes_read, sizeof(*buf), files[i]);
			fflush(files[i]);
		}
	}

	cleanup(files, nfiles);
}

void cleanup(FILE **files, size_t nfiles) {
	for (size_t i=0; i < nfiles; ++i) {
		if (files[i])
			fclose(files[i]);
	}

	if (files)
		free(files);

	exit(EXIT_FAILURE);
}

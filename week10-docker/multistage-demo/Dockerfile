# 멀티스테이지: builder에서 빌드하고, 결과 파일 하나만 빈 이미지(scratch)로 옮긴다.
FROM golang:1.24 AS builder
WORKDIR /src
COPY go.mod main.go ./
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /out/server .

FROM scratch
COPY --from=builder /out/server /server
EXPOSE 8000
USER 10001
CMD ["/server"]

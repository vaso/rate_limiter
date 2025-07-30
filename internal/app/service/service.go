package service

//nolint:gofumpt
import (
	"context"

	"github.com/golang/protobuf/ptypes/empty"
	"google.golang.org/protobuf/types/known/emptypb"
	"rate_limiter/config"
	"rate_limiter/pb"
)

type Service struct {
	pb.UnimplementedRateLimiterServiceServer
	rateLimiterService *RateLimiterService
}

func NewService(ctx context.Context, config config.AppConfig) (*Service, error) {
	rateLimiterService, err := NewRateLimiterService(ctx, config)
	if err != nil {
		return nil, err
	}
	return &Service{
		rateLimiterService: rateLimiterService,
	}, nil
}

func (s *Service) Allow(ctx context.Context, req *pb.LoginRequest) (*pb.LoginResponse, error) {
	res := s.rateLimiterService.Check(ctx, req.GetLogin(), req.GetPassword(), req.GetIP())

	return &pb.LoginResponse{Ok: res}, nil
}

func (s *Service) ResetBucket(ctx context.Context, req *pb.ResetRequest) (*emptypb.Empty, error) {
	s.rateLimiterService.ResetBucket(ctx, req.GetLogin(), req.GetIP())

	return &empty.Empty{}, nil
}

func (s *Service) AddIPToBlackList(ctx context.Context, req *pb.IPRequest) (*emptypb.Empty, error) {
	_, err := s.rateLimiterService.AddToBlacklist(ctx, req.GetIP())
	if err != nil {
		return nil, err
	}
	return &empty.Empty{}, nil
}

func (s *Service) RemoveIPFromBlackList(ctx context.Context, req *pb.IPRequest) (*emptypb.Empty, error) {
	_, err := s.rateLimiterService.RemoveFromBlacklist(ctx, req.GetIP())
	if err != nil {
		return nil, err
	}
	return &empty.Empty{}, nil
}

func (s *Service) AddIPToWhiteList(ctx context.Context, req *pb.IPRequest) (*emptypb.Empty, error) {
	_, err := s.rateLimiterService.AddToWhitelist(ctx, req.GetIP())
	if err != nil {
		return nil, err
	}
	return &empty.Empty{}, nil
}

func (s *Service) RemoveIPFromWhiteList(ctx context.Context, req *pb.IPRequest) (*emptypb.Empty, error) {
	_, err := s.rateLimiterService.RemoveFromWhitelist(ctx, req.GetIP())
	if err != nil {
		return nil, err
	}
	return &empty.Empty{}, nil
}
